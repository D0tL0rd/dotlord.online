---
title: "Redirect to the latest Hashnode blog post using Cloudflare workers"
author: ["Shahin Azad"]
draft: false
---

## Use Case {#use-case}

This is a very trivial usecase, where you need to create an static URL
to always point to the latest blog post dynamically. The blog in this
scenario was hosted on [Hashnode](https://hashnode.com/) which doesn't provide the
functionality out of the box but provides a [GraphQL](https://gql.hashnode.com/) API which makes it
possible ([more info](https://api.hashnode.com/)).


## Design {#design}

In this case [Cloudflare]({{< relref "20241017125846-cloudflare.md" >}}) was used to manage the domain resources, so I
thought we can utilize [Cloudflare]({{< relref "20241017125846-cloudflare.md" >}}) workers for this purpose.


## Implementation {#implementation}


### Initialize the repository {#initialize-the-repository}

Use [Cloudflare]({{< relref "20241017125846-cloudflare.md" >}}) wrangler to initialize the repo based of `wrangler`:

```sh
npm create cloudflare@latest -- latest-blog-url
```


### The logic {#the-logic}

```javascript
async function handleRequest(request) {
    const graphqlEndpoint = `https://gql.hashnode.com`;

    const graphqlQuery = `
  query Publication( $id: ObjectId="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ) {
  publication(id: $id) {
        isTeam
        title
        posts(first: 1) {
          edges {
            node {
              title
              brief
              url
            }
          }
        }
      }
    }
  `;

    const graphqlResponse = await fetch(graphqlEndpoint, {
        method: 'POST',
        headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0',
            'Accept': 'application/json, multipart/mixed',
            'Accept-Language': 'en-US,en;q=0.5',
            'Referer': 'https://gql.hashnode.com/',
            'Content-Type': 'application/json',
            'gcdn-debug': '1',
            'Origin': 'https://gql.hashnode.com',
            'DNT': '1',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin',
            'Priority': 'u=0',
            'Pragma': 'no-cache',
            'Cache-Control': 'no-cache',
        },
        body: JSON.stringify({ query: graphqlQuery }),
        cf: {
            cacheTtl: 0,
            cacheEverything: false,
        },
    });

    const responseData = await graphqlResponse.json();

    const url = responseData.data.publication.posts.edges[0].node.url;
    const statusCode = 303;
    const response = new Response(null, {
        status: statusCode,
        headers: {
            Location: url,
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            Pragma: 'no-cache',
            Expires: '0',
        },
    });
    return response;
}

export default {
    async fetch(request) {
        return handleRequest(request);
    },
};
```


#### Description {#description}

-   The query part is quite trivial. The only important thing is I'm
    using publication ID for the query. In my tests, when using the blog
    url when I was using a custom domain, was causing a cache of the old
    response for a longer period of time. To get publication id, you can
    use the following query on [Hashnode GraphQL playground](https://gql.hashnode.com):
    ```graphql
    query Publication($host: String = "PUBLICATION-URL") {
     publication(host: $host) {
      id
     }
    }
    ```
-   For the header, I also used all the headers `gql.hashnode.com`
    submits. Without this and/or the the publication id, the result
    wasn't getting updated at all.
-   the `cf` section, indicates [Cloudflare]({{< relref "20241017125846-cloudflare.md" >}}) cache to not get
    engated.
-   I'm using [Http Status]({{< relref "20241017131307-http_status.md" >}}) 303, which means see other, and sound a
    prefect match as I don't want to make this redirect permanent or
    cached by browser.


### Deployment {#deployment}

If you haven't logged in:

```sh
wrangler login
```

And then:

```sh
wrangler deploy
```

Also it's possible to connect a [GitHub]({{< relref "20241017131521-github.md" >}}) repository to the
[Cloudflare]({{< relref "20241017125846-cloudflare.md" >}}) so it'll automatically pick it up when you
push something to the repo.


### Custom Domain {#custom-domain}

Using routes it's possible to setup a custom domain. Add the following
to `wrangler.toml`:

```toml
routes = [
   { pattern = "domain.tld/new/*", zone_name = "domain.tld" }
]
```


### [Nix]({{< relref "20241017131710-nix.md" >}}) Notes {#nix--20241017131710-nix-dot-md--notes}

If you are using [NixOS]({{< relref "20241017131726-nixos.md" >}}), you can't run `wrangler` command installed with
`npm`. In this case, either use `npx` (update `package.json` by prefixing
`wrangler` command with `npx`), or install `wrangler` using [Nix]({{< relref "20241017131710-nix.md" >}}) which I
did like following in [Devenv]({{< relref "20241017131922-devenv.md" >}}):

```nix
packages =
  with pkgs;
  []
  ++ (with nodePackages; [
    wrangler
  ])
```
