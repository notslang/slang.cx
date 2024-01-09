# Reverse-Engineering Instagram IDs

As part of our analytics department at Carrot, we do quite a bit of programmatic scraping of social platforms to gather data on how our posts are performing. Internally, this is a part of a project called "Sherlock", which we built to automate all of our data-gathering & querying tasks. This post is not about Sherlock; it's about an observation I made while updating one of Sherlock's Instagram scrapers.

If you look at the Instagram API, it has ids that look like `908540701891980503_1639186`, for each post, but they don't use those ids in their post URLs - they use a different type of id that looks like `ybyPRoQWzX`. This is, of course, pretty weird to have 2 identifiers for the same post. But, if you look at the identifiers of several posts, and how their numbers correlate, it becomes obvious that there's a connection between these 2 types of identifier.

Looking at the first number, `908540701891980503`, which identifies the post itself (the latter part identifies the user), and comparing it to the id in the URL, we see that there's a 18 to 10 ratio in characters. So if they're directly related, there's a higher information density per character in the URL. We can try converting the base10 id to base64 to test this out. `9:0:8:5:4:0:7:0:1:8:9:1:9:8:0:5:0:3_10` becomes `50:27:50:15:17:40:16:22:51:23_64`. Now we've got the right number of digits!

Next, lets check and see if there is a logical mapping from number to letter. Unsorted, it looks like this:

number | letter
------ | ------
50     | y
27     | b
50     | y
15     | P
17     | R
40     | o
16     | Q
22     | W
51     | z
23     | X

Immediately, we can see signs of a deterministic conversion from one id to the other (rather than the 10-char id being a random string that's stored with the number id): The number 50 is matched with the letter "y" twice. But if we sort by number, it becomes even more clear:

number | letter
------ | ------
15     | P
16     | Q
17     | R
22     | W
23     | X
27     | b
40     | o
50     | y
50     | y
51     | z

We see a familiar type of sorting: A-Z, then a-z. This assumption holds true as we apply the transformation to other ids. Note: in the table below I have removed duplicates.

number | letter
------ | ------
00     | A
01     | B
02     | C
03     | D
07     | H
08     | I
09     | J
10     | K
11     | L
13     | N
15     | P
16     | Q
17     | R
20     | U
22     | W
23     | X
24     | Y
26     | a
27     | b
29     | d
32     | g
34     | i
36     | k
37     | l
40     | o
42     | q
43     | r
47     | v
50     | y
51     | z
56     | 4
62     | -
63     | _

It's basically the same encoding table that's used in the standard character-representation of base64, except the `+` and `/` characters are replaced with `-` and `_`, respectively. This replacement is probably because `/` is a special character in URLs, and `+` is a special character in query strings.

## Implications

By knowing how these 2 types of ids are linked, we learn a few things about Instagram.

### Uniqueness / Extra Data

We already know that the id they use in their URL is unique across all of Instagram, based on the URL structure: `https://instagram.com/p/ybyPRoQWzX`. But since that is able to be converted into the first section of their numeric ID, we know that the first section of their numeric id is also unique across all of Instagram, even without the second part used to identify the user.

Surprisingly, this uniqueness of the first part of the numeric id actually translates to the workings of their internal API. By inspecting the requests made by Instagram's website, we can see that the normal format for getting posts by a given user is `https://instagram.com/<username>/media/?max_id=<numeric id>` (like `https://instagram.com/gitamba/media/?max_id=915362118751716223_7985735`). But the API will actually still work if you omit the "user part" of the numeric id (like `https://instagram.com/gitamba/media/?max_id=915362118751716223`). In fact, the underscore in that id, and everything after it is completely ignored, so a request like `https://instagram.com/gitamba/media/?max_id=915398248830305252_whatever` will still return exactly the same response as the previous 2 examples. It's likely that filtering down to a particular user's posts is done with the first segment of the URL, making it a mystery as to why they include the user-specific section of the id in the `max_id` field at all.

### Convertibility

The most important implication (for me) is that I don't need to store their base10 id in Sherlock's database at all, because it can be recreated entirely just by transforming the base64 id they use in their URL.

### Further Analysis

There's a little more information you can get from an Instagram id, if you happen to know [how they make them](http://instagram-engineering.tumblr.com/post/10853187575/sharding-ids-at-instagram). They don't mention what their internal epoch is, but knowing the dates associated with some ids, we can calculate it with pretty good accuracy. The following is a table of example posts that I gathered the creation times for.

post id  (base 10) | known post created time (unix time)
------------------ | -----------------------------------
908540701891980503 | 1422526513s
936303077400215759 | 1425836046s
188449103402467464 | 1336684905s

Since the post id is a 64 bit integer, we'll start by converting into binary & padding it to 64 bits (to illustrate this as graphically as I can).

post id (base 10)  | post id (base 2)
------------------ | ----------------------------------------------------------------
908540701891980503 | 0000110010011011110010001111010001101000010000010110110011010111
936303077400215759 | 0000110011111110011010101011000000101010100010111000000011001111
188449103402467464 | 0000001010011101100000010111011000001010100010111000000010001000

Next, we'll take the first 41 bits of each id (which represents the milliseconds since Instagram's epoch), and convert it back to decimal.

first 41 bits of post id                  | time since Instagram epoch
----------------------------------------- | --------------------------
00001100100110111100100011110100011010000 | 108306491600ms
00001100111111100110101010110000001010101 | 111616024661ms
00000010100111011000000101110110000010101 | 22464883733ms

Finally, we subtract the time since the Instagram epoch from the post created time (in unix time), for each post. This gives us the approximate Instagram epoch in unix time. If we've done everything correctly, then each value should be about equal. The small discrepancies come from the fact that the created time is rounded to the nearest second, rather than the nearest ms, like the id uses.

created time | time since Instagram epoch | Instagram epoch (unix time)
------------ | -------------------------- | ---------------------------
1422526513s  | 108306491600ms             | 1314220021.400s
1425836046s  | 111616024661ms             | 1314220021.339s
1336684905s  | 22464883733ms              | 1314220021.267s

Thus, the Instagram epoch is ~1314220021 unix time, aka: 9:07pm UTC on Wednesday, August 24, 2011. This seems like a pretty random time to set the epoch at, but I assume this is around the time they were making the transition from consecutive auto-incrimenting ids to their current format.

Anyway, now that we know the epoch, we can convert all the way from a URL of an Instagram post, to the exact time it was posted... Which I think is a pretty interesting property to discover. Of course, I'm still going to keep the post time stored in Sherlock's database, separate from the id, since it makes it easier to query.

You can also get the ID of the Instagram shard that the post was processed on from the id, which might be interesting if those shards are distributed geographically and in a way that is usually closest to the user, but that's an idea for another post.

## Ids Used in Testing

These are the ids that I used to create the tables earlier in the post. The 2 shorter ones are from 2011, when they used auto-incrementing ids.

id in base 10      | id in base64                  | converted to chars
------------------ | ----------------------------- | ------------------
936303077400215759 | 51:62:26:43:00:42:34:56:03:15 | z-arAqi4DP
908540701891980503 | 50:27:50:15:17:40:16:22:51:23 | ybyPRoQWzX
283455759575646671 | 15:47:02:24:11:51:02:56:07:15 | PvCYLzC4HP
205004325645942831 | 11:24:20:37:36:23:34:56:00:47 | LYUlkXi4Av
188449103402467464 | 10:29:32:23:24:10:34:56:02:08 | KdgXYKi4CI
409960495          | 24:27:56:00:47                | Yb4Av
167566273          | 09:63:13:47:01                | J_NvB
