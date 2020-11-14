---
title: Different Ways of Accessing an API with JavaScript
date: 2017-05-04
tags:
    - JavaScript
    - API
photo: katie-chase-180320.jpg
---

Comparing the good old jQuery with modern alternatives. Fetch is an upcoming native standard. Axios is an elegant promise based HTTP client. In the end everything is wrapped together with Vue.js to create an example [online base62 decoder](https://base62.io/).

## Creating a Simple API

For demonstrating purposes lets create a simple JSON API. You can also call it a REST API but that might end with endless discussion on what is REST and what is not. As a basis I used a slimmed down version of [Slim 3 API Skeleton](https://github.com/tuupola/slim-api-skeleton).

```text
$ composer create-project --no-interaction --stability=dev \
  tuupola/slim-api-skeleton api.base62.io
```

<!--more-->

After installing I removed features such as authentication which are not needed for this demonstration.

API itself contains two routes. First one for encoding data into base62.

```php
$app->post("/encode", function ($request, $response, $arguments) {
    $body = $request->getParsedBody();
    $encoded = (new Base62)->encode($body["data"]);
    return $response->withStatus(200)
        ->withHeader("Content-Type", "application/json")
        ->write(json_encode(["encoded" => $encoded], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
});
```

Second one for decoding the base62 string back to original.

```php
$app->post("/decode", function ($request, $response, $arguments) {
    $body = $request->getParsedBody();
    $decoded = (new Base62)->decode($body["data"]);
    return $response->withStatus(200)
        ->withHeader("Content-Type", "application/json")
        ->write(json_encode(["decoded" => $decoded], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
});
```

Both expect a JSON object as input with `data` property containing the payload.

```text
$ curl https://api.base62.io/encode \
    --request POST \
    --header "Content-Type: application/json" \
    --data '{ "data": "Hello world!" }'

{
    "encoded": "T8dgcjRGuYUueWht"
}
```

```text
$ curl https://api.base62.io/decode \
    --request POST \
    --header "Content-Type: application/json" \
    --data '{ "data": "T8dgcjRGuYUueWht" }'

{
    "decoded": "Hello world!"
}
```

## jQuery

jQuery has been the trusted workhorse for a long time. It still gets the job done and does it very well. However altering the DOM manually will get cumbersome with bigger projects. It is also not considered fashionable anymore.

There is a `$.post()` shortcut. However  it will send the request as <nobr>`application/x-www-form-urlencode`</nobr> and you have to construct the JSON string and set the `Content-Type` header manually.

```html
<p id="encoded">Encoding...</p>
<p id="decoded">Decoding...</p>
<p id="error"></p>
```

```javascript
$.ajax("https://api.base62.io/encode", {
    type: "POST",
    data: JSON.stringify({ data: "Hello world!" }),
    contentType: "application/json",
}).done(function (data) {
    $("#encoded").html(data.encoded);
}).fail(function (xhr, status, error) {
    $("#error").html("Could not reach the API: " + error);
});

$.ajax("https://api.base62.io/decode", {
    type: "POST",
    data: JSON.stringify({ data: "T8dgcjRGuYUueWht" }),
    contentType: "application/json",
}).done(function (data) {
    $("#decoded").html(data.decoded);
}).fail(function (xhr, status, error) {
    $("#error").html("Could not reach the API: " + error);
});
```

[JSFiddle](https://jsfiddle.net/tuupola/2ftyo393/)

## Fetch

[Fetch](https://developer.mozilla.org/en/docs/Web/API/Fetch_API) is a modern  equivalent to XMLHttpRequest. It provides much more sane API for making HTTP requests. Fetch is still experimental but will be a future standard. Browser support is decent. Unsurprisinly IE does not support fetch but there is there is a [polyfill](https://github.com/github/fetch) which fixes the problem.

Usage is quite similar to jQuery. You still have to set the headers and convert the payload to JSON string manually. There are no shortcuts for different request methods. There also are some gotchas with error handling. For example a `404 Not Found` response will not cause the promise to be rejected. Instead you have to check the `response.ok` property and throw an error yourself.

In example below I am still altering the DOM manually. This time only with vanilla JavaScript.

```html
<p id="encoded">Encoding...</p>
<p id="decoded">Decoding...</p>
<p id="error"></p>
```

```javascript
fetch("https://api.base62.io/encode", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({ data: "Hello world!" }),
    mode: "cors"
}).then(function(response) {
    if (response.ok) {
        return response.json();
    } else {
        throw new Error("Could not reach the API: " + response.statusText);
    }
}).then(function(data) {
    document.getElementById("encoded").innerHTML = data.encoded;
}).catch(function(error) {
    document.getElementById("error").innerHTML = error.message;
});

fetch("https://api.base62.io/decode", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({ data: "T8dgcjRGuYUueWht" }),
    mode: "cors"
}).then(function(response) {
    if (response.ok) {
        return response.json();
    } else {
        throw new Error("Could not reach the API: " + response.statusText);
    }
}).then(function(data) {
    document.getElementById("decoded").innerHTML = data.decoded;
}).catch(function(error) {
    document.getElementById("error").innerHTML = error.message;
});
```
[JSFiddle](https://jsfiddle.net/tuupola/ak8woea3/)

## Axios With Vue.js

[Axios](https://github.com/mzabriskie/axios) is a promise based HTTP client for the browser and node.js. Usage is similar to `fetch()` with the exception that axios provides more developer friendly high level API. Data is converted automatically from and to JSON. Error handling has less surprises. Meaning `404` is considered an error.

Example below uses [Vue](https://vuejs.org/) for modifying the DOM. It uses declarative rendering. When value of `app.encoded`, `app.decoded` or `app.error` changes the HTML will also update automatically. For a small example like this the amount of code looks almost the same. In the long run, however framework like Vue will save you from the spaghetti code which will result from writing the UI code yourself.

```html
<div id="app">
  <p>{{ encoded }}</p>
  <p>{{ decoded }}</p>
  <p>{{ error }}</p>
</div>
```

```javascript
var app = new Vue({
    el: "#app",
    data: {
        encoded: "Encoding...",
        decoded: "Decoding...",
        error: null
    },
    created: function () {
        var self = this
        axios
            .post("https://api.base62.io/encode", {
                data: "Hello world!"
            })
            .then(function (response) {
                self.encoded = response.data.encoded
            })
            .catch(function (error) {
                self.error = "Could not reach the API: " + error
            })

        axios
            .post("https://api.base62.io/decode", {
                data: "T8dgcjRGuYUueWht"
            })
            .then(function (response) {
                self.decoded = response.data.decoded
            })
            .catch(function (error) {
                self.error = "Could not reach the API: " + error
            })
    }
});
```

[JSFiddle](https://jsfiddle.net/tuupola/jh5bsm5z/)

Slightly modified version of the above code is also live on [base62.io](https://base62.io/).

## Other Contenders

There are other contenders such as [SuperAgent](https://github.com/visionmedia/superagent) and [qwest](https://github.com/pyrsmk/qwest). I tried several but have narroved it down to either [axios](https://github.com/mzabriskie/axios) or [fetch](https://developer.mozilla.org/en/docs/Web/API/Fetch_API). I like the simplicity of axios. It is a perfect match for simplicity of Vue.
