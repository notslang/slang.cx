# The joys of running a public IPFS gateway in 2023

I've been running a public IPFS gateway since 2016 at `ipfs.slang.cx/ipfs`.
It started out as a means to share files between friends. I had a script that uploaded files to the server, ran `ipfs add` on them, and printed out a link that I could send to let other people download the file. Like a bare-bones file sharing site.

This worked great, and I am happy to be running a small component of the IPFS network. However, in the years that I kept it running, I ran into several issues.

To be clear, I really like the idea of IPFS. Any website that contains content that's worth reading should have an archival strategy, and IPFS is a great way to do that. Also, I'm only talking about running a public gateway. These issues don't apply to a local installation of IPFS.

The first couple years were uneventful because nobody but myself and a few friends knew that the site existed.

I think that changed when someone added my site to the [IPFS gateway checker](https://github.com/ipfs/public-gateway-checker).

The first issue I ran into was an increase in traffic. I was getting massive numbers of requests from bots.

CPU was stuck at 100% and the server that it was running on was basically unusable.

Simple IP banning wouldn't work because the requests were coming from thousands of different addresses.

I ended up needing to use Cloudflare to deal with this. I don't like having to depend upon Cloudflare, but the site would be completely unusable without it.

At the beginning of 2022 I ran into my second issue - DMCA requests.
