So, if you look at the Instagram API, it has these ids that look like `908540701891980503_1639186`, but they don't use those in their URL - they use a different type of id that looks like `ybyPRoQWzX`. This is, of course, pretty weird to have 2 identifiers for the same post. But, if you look at the identifiers of several posts, and how their numbers correlate, it becomes obvious that there's a connection between these 2 types of identifier.

Looking at the first number, `908540701891980503`, which identifies the post itself (the latter part identifies the user), and comparing it to the id in the URL, we see that there's a 18 to 10 ratio in characters. So if they're related, there's a higher information density per character in the URL. We can try converting the base10 id to base64 to test this out. `9:0:8:5:4:0:7:0:1:8:9:1:9:8:0:5:0:3_10` becomes `50:27:50:15:17:40:16:22:51:23_64`. Now we've got the right number of digits!

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

We see a familiar type of sorting: A-Z, then a-z. This assumption holds true as we apply the transformation to other ids:

number | letter
------ | ------
02     | C
13     | N
15     | P
15     | P
16     | Q
17     | R
18     | S
22     | W
22     | W
22     | W
22     | W
23     | X
24     | Y
27     | b
34     | i
40     | o
41     | p
48     | w
48     | w
48     | w
48     | w
50     | y
50     | y
50     | y
50     | y
51     | z
54     | 2
58     | 6
61     | 9
62     | -
