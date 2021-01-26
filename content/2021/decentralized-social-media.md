---
title: Decentralized Social Media
date: 2021-01-21T00:05:00+02:00
draft: false
image: img/2021/american-sector.jpg
description: Leaving all politics a side, this is not the way the Internet was supposed to be.
tags:
    - Internet
---

![Berlin wall American sector](/img/2021/american-sector.jpg)

<small><i>Photo by <a href="https://unsplash.com/@etiennegirardet?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Etienne Girardet</a> on <a href="https://unsplash.com/s/photos/berlin-wall?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></i></small>

This is a post I have started to write several times already. First time 2017, then again in 2019 and 2020. I do not remember what was the drama then. Each time I procrastinated and thought things are not that bad yet.

Leaving all politics a side, this is not the way the Internet was supposed to be.

_"The first truth is that the liberty of a democracy is not safe if the people tolerate the growth of private power to a point where it becomes stronger than their democratic state itself.  That, in its essence, is fascism -- ownership of government by an individual, by a group, or by any other controlling private power."_

 —Franklin D. Roosevelt, excerpt from [message to Congress, April 29, 1938](https://publicpolicy.pepperdine.edu/academics/research/faculty-research/new-deal/roosevelt-speeches/fr042938.htm)

 **TL;DR: Social media services such as Twitter and Instagram could be recreated with an RSS like file format. No platform needed.**

<!--more-->

## The Problem

Everything is centralized which gives the control of allowed ideas to the owner of the platform. If you deviate from the allowed thinking you will be silenced.

![Berlin wall celebration](/img/2021/jahrestag.jpg)
<i><small><a href="https://commons.wikimedia.org/wiki/File:Bundesarchiv_Bild_183-1986-0813-454,_Berlin,_25._Jahrestag_zur_Errichtung_der_Mauer.jpg">Bundesarchiv, Bild 183-1986-0813-454 / Franke, Klaus / CC-BY-SA 3.0</a>, <a href="https://creativecommons.org/licenses/by-sa/3.0/de/deed.en">CC BY-SA 3.0 DE</a>, via Wikimedia Commons</small></i>

There have been attemps to create platforms which allow wider spectrum of opinion. These attempts are usually hindered by companies such as Apple and Google by [removing the apps](https://nypost.com/2021/01/09/apple-joins-google-in-suspending-parler-from-app-store/) from their app stores.

Technically inclined Android users can install apps from alternative sources but even that does not help. If they don't like you, companies such as Visa and Mastercard will not only blacklist the company but also [the family members](https://news.gab.com/2020/06/26/social-credit-score-is-in-america-visa-blacklisted-my-business-and-my-family-for-building-gab/) of the founders of the platform in order to stop you get funding for running your app.

If you are still able to get alternate sources of funding companies such as Amazon [will stop providing you hosting services](https://www.bloomberg.com/news/articles/2021-01-09/amazon-worker-group-calls-for-cloud-unit-to-drop-parler).

## The Solution

No, the solution is not blockchain blockchain something. The solution is not having a new shiny platform either. Platforms are depedent on all the three things mentioned above.

Solution is to have an agreed file format and/or protocol for publishing the usual social media things such as posts, likes and reposts. Each user can publish this file anywhere they wish, as long as it is publicly accessible from the Internet.

![Peek through Berlin wall](/img/2021/brandenburger.jpg)
<i><small><a href="https://commons.wikimedia.org/wiki/File:Bundesarchiv_Bild_183-1990-0429-411,_Berlin,_Abriss_der_Mauer_am_Brandenburger_Tor.jpg">Bundesarchiv, Bild 183-1990-0429-411 / Schindler, Karl-Heinz / CC-BY-SA 3.0</a>, <a href="https://creativecommons.org/licenses/by-sa/3.0/de/deed.en">CC BY-SA 3.0 DE</a>, via Wikimedia Commons</small></i>

Simplest way to publish a feed would be to upload the single feed file to your own webserver. Alternatively it could be a [GitHub Gist](https://gist.github.com/) or a [Pastebin paste](https://pastebin.com/). If you are worried about webhost cencorship
 [IPFS](https://ipfs.io/) might help. People preferring to stay anonymous could use [onion services](https://community.torproject.org/onion-services/).

User who wants to follow you subscribes to the url of your feed with their client software. The client software then periodically checks for updates and renders a timeline view similar as Twitter or Instagram.

This is same as what [RSS](https://en.wikipedia.org/wiki/RSS) was for blogging world. Users decide what they subscribe to and what they see. There are no algorithms doing decisions on users behalf. Publishers can publish on any Internet connected server. Anyone can create a client software.

There is no single point of failure.

## The File Format

I have given this some though. This might change when doing an actual implementation. Instead of XML I would use JSON which is lighter to parse. Goal is to be not bloated and easy to implement.

The `title` is your displayed username and the `description` is the tagline or what Instagram calls a bio.

The `url` is an array which contains one or more addresses where the client can access your feed. Only the first one is fetched by default. If the first one cannot be accessed next one in the array will be fetched instead. This is useful if you lose access to your primary feed you will not lose your subscribers.

Rest of the json contains your posts, reposts and likes.

```json
{
    "title": "Mika Tuupola",
    "description": "Technology guy gone advertising",
    "url": [
        "https://appelsiini.net/social.json",
        "https://example.org/social.json"
    ],
    "posts": [],
    "reposts": [],
    "likes": []
}
```

### Posts

Each post consists of an `id`, `body`, one or more `media` files and an optional `ref`. The `id` should be an instance of [K-Sortable Unique IDentifier](https://github.com/segmentio/ksuid). KSUID was chosen because it has an embedded timestamp so there is no need for a separate timestamp in json data. KSUID can also be naturally sorted by their creation time which simplifies rendering the timeline.

The post content itself is in plaintext `body` property. Clients should be able to parse hashtags in the body. There probably should be some arbitrary character limit to discourage too long post. Maybe 1024 characters?

User can optionally post one or more images and / or videos in the `media` property. To enable single file publishing clients must be able to parse [data urls](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs). It is probably good idea to also support traditional urls.

If the post is a reply `ref` should contain the feed `url` and the `id` of the post being replied to. If post is not a reply `ref` should be `null`. Depending on settings client can use this to fetch the `ref` feed even if user does not currently subscribe to it.

```json
{
    ...

    "posts": [
        {
            "id": "p6UEyCc8D8ecLijAI5zVwOTP3D0",
            "body": "Lorem ipsum dolor sit amet. #foo #bar",
            "media": [
                "data:image/png;base64,PAKBjRACCARjPAKBJggg==",
                "data:image/png;base64,FCKBjRAKCARjPAKAAgeg=="
            ],
            "ref": "https://example.com/social.json#1mr52fioahBqXD7HVgZ4IkKRrUf"

        },
        {
            "id": "0o5Fs0EELR0fUjHjbCnEtdUwQe3",
            "body": "Ut enim ad minim veniam. #foo",
            "media": [
                "https://example.com/foo.png"
            ],
            "ref": null
        }
    ]
}
```

### Reposts

Repost happens when someone posts your post to their followers. Repost consists of `id` which is a KSUID and a `ref` to the post which is being posted. Thanks to KSUID simply sorting by the id puts the reposts in to correct location in the timeline.

```json
{
    ...

    "reposts": [
        {
            "id": "1mr5Btzoz5G9M4Wl5ZZo9K4Y6oQ",
            "ref": "https://example.org/social.json#1mr5F1roAhBc9YFFftk6WNiZuQP"
        },
        {
            "id": "1mr5CRWwT8FRHrsq7Lqn3hJ3KV0",
            "ref": "https://example.org/social.json#1mr5HcxkKbNqs9X5oQ0fIfzENqP"
        },
        {
            "id": "1mr5DK70OQuTUPLvsCML2mkMHdB",
            "ref": "https://example.com/social.json#1mr5InVxCYH0dXSncivI667ESpb"
        }
    ]
}
```

### Likes

To be honest I am not sure if this is needed. However seeing how popular such a feature is with now, why not. Same as repost, a like consists of `id` which is a KSUID and a `ref` to the post which is being liked.

```json
{
    ...

    "likes": [
        {
            "id": "0uk1Hbc9dQ9pxyTqJ93IUrfhdGq",
            "ref": "https://example.org/social.json#p6UEyCc8D8ecLijAI5zVwOTP3D0"
        },
        {
            "id": "0uk1HdCJ6hUZKDgcxhpJwUl5ZEI",
            "ref": "https://example.org/social.json#1mr519x29wy6WAcgAftSb33dEgC"
        },
        {
            "id": "0uk1HcdvF0p8C20KtTfdRSB9XIm",
            "ref": "https://example.com/social.json#1mr52fioahBqXD7HVgZ4IkKRrUf"
        },
        {
            "id": "0uk1Ha7hGJ1Q9Xbnkt0yZgNwg3g",
            "ref": "https://example.org/social.json#1mr5448rXkn02LkyFXhOZNaCurh"
        }
    ]
}
```

## The Problems

### Discovery

Discovery means how can one find new people to subscribe to? I think this problem will fix itself in the same way the Internet has always fixed it. Primary discovery source will be reposts and likes. There will also most likely be people writing _"Awesome People to Follow"_ style lists.

By design clients will index feeds with two degrees of separation. This means if you subscribe to feed `A` and that feed has a repost or a like to a feed `B` then your client will fully index both feeds `A` and `B` but will not index reposts or likes in feed `B`.

Clients can optionally have a setting to control the degrees of separation. If user sets this to `3` and the feed `B` has a repost from feed `C` the client software will index  feeds `A`, `B` and `C`.

Posts indexed from feeds you do not directly follow can be used for rendering hashtags views and searches. There probably is a practical limit how many dedrees of separation is useful to index.

### Identity

There is no usernames to reserve. Anyone can post anything under any name. How do people know you are who you are? Blogs have the same problem. Obvious proof of your identity would be your own domain. Maybe something could be done with [PGP](https://gnupg.org/).

This is somehing I do not have a good answer to.  However it is good to remember that even with usernames Twitter et al. have the problem of fake user accounts. In the end in the Internet you never know who the people really are.

### Technical Barrier

![Peek through Berlin wall](/img/2021/peek.jpg)

<i><small>Image by <a href="https://pixabay.com/users/wal_172619-12138562/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4686898">wal_172619</a> from <a href="https://pixabay.com/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4686898">Pixabay</a></small></i>

Even if not especially high, the technical barrier for uploading the feed file to a webserver is probably too high for 80% of current social media users. The client software should enable uploading the feed file via ftp or scp. There is still problem of setting up the web server.

In the end there will most likely be multiple companies which offer hosting for the feed file. Same companies might offer their own reader clients. This will contradict with the requirement of not being dependent in a company. It is still better than being dependent on single social media platform though.