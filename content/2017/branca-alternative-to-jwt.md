---
title: Branca as an Alternative to JWT?
date: 2017-08-06
tags:
    - API
    - JavaScript
photo: katie-chase-180320.jpg
payoff: IETF XChaCha20-Poly1305 AEAD
---

[Branca](https://github.com/tuupola/branca-spec) is a catchy name for IETF XChaCha20-Poly1305 AEAD message with an additional version number and timestamp. It is well suited to be used as an authenticated and encrypted API token. [Branca specification](https://github.com/tuupola/branca-spec) does not specify the payload format. Among others you can use for example JWT payloads but still have modern encryption and smaller token size provided by Branca.

Currently there are implemenations
for [JavaScript](https://github.com/tuupola/branca-js), [Elixir](https://github.com/tuupola/branca-elixir), [Go](https://github.com/hako/branca) and [PHP](https://github.com/tuupola/branca-php) and a [command line tool](https://github.com/tuupola/branca-cli) for creating and inspecting tokens.


<!--more-->

> Heads up! JWT itself is the payload part of a larger standard called Javascript Object Signing and Encryption (JOSE). That said the term JWT has become ubiquitous when actually referring JSON Web Signature (JWS) or JSON Web Encryption (JWE). In this article the term JWT refers to JWS.

Branca is based on [Fernet specification](https://github.com/fernet/spec).

## What is Fernet?

Fernet takes an user provided message, a secret key and the current time and generates an Authenticated Encrypted (AE) token. [Authenticated encryption](https://en.wikipedia.org/wiki/Authenticated_encryption) specifies a way to secure a message so that a 3rd party cannot fake it, alter it nor read it.

Fernet token is a Base64URL encoded concatenation of the following fields:

```text
Version (1B) | Timestamp (8B) | IV (16B) | Ciphertext (*B) | HMAC (32B)
```

Where HMAC is 256-bit SHA256 HMAC of the concatenation of the following fields:

```text
Version (1B) | Timestamp (8B) | IV (16B) | Ciphertext (*B)
```

Fernet seems not to be maintained anymore. There has been no updates for the spec in three years. Original developers are in radio silence.

## Introducing Branca

[Branca token](https://github.com/tuupola/branca-spec) is a modernized version of Fernet. Branca aims to be secure, easy to implement and have a small token
size. Branca token is a Base62 encoded concatenation of the following fields:

```text
Version (1B) | Timestamp (4B) | Nonce (24B) | Ciphertext (*B) | Tag (16B)
```

Main differences to the Fernet spec are:

1. Instead of AES 128 CBC and SHA256 HMAC, Branca uses [XChaCha20-Poly1305](https://download.libsodium.org/doc/secret-key_cryptography/xchacha20-poly1305_construction.html) Authenticated Encryption with Additional Data (AEAD).
2. Instead of of Base64URL encoding, Branca uses Base62 for the string representation of the token.
3. Instead of 64-bit unsigned big-endian integer, the timestamp  is 32-bit unsigned big-endian integer. This is slightly easier to implement and saves a few bytes, but is still valid until year 2106 when integer oveflow will happen.

## Alternative to JWT You Say?

Branca specification defines only the external format of the token. Payload format
is intentionally undefined. This means you could still use the JWT payload without
the JOSE overhead.

For comparison I will use the typical JWT setup seen in the wild. Payload is
unencrypted but both header an payload are authenticated using HMAC SHA-256. In other words a JWS token. Header describes the paylod type and signing algorithm.


```json
{ "typ" : "JWT", "alg" : "HS256" }
```

Payload is a JSON Web Token. This example payload is taken from [RFC7515](https://datatracker.ietf.org/doc/rfc7515/).


```json
{ "iss" : "joe", "exp" : 1300819380, "http://example.com/is_root" : true }
```

We can generate the token with a little bit of JavaScript.

```javascript
const key = "supersecretkeyyoushouldnotcommit";
const jwt = require("jsonwebtoken");

const token = jwt.sign({
    "iss" : "joe",
    "exp" : 1300819380,
    "http://example.com/is_root" : true
}, key, {noTimestamp: true});

const payload = jwt.verify(token, key, {ignoreExpiration: true});

console.log(token);
console.log(payload);
```

The complete signed and Base64URL encoded token is a 168 character string.

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJpc3MiOiJqb2UiLCJleHAiOjEzMDA4M
TkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQnf_uy1ZrKiO9F4vq
hK7mXrqIbDS799K0DhfDi5g0im8

{ iss: 'joe',
  exp: 1300819380,
  'http://example.com/is_root': true }
```

Now let's compare this to a Branca token with exactly the same payload.

```javascript
const key = "supersecretkeyyoushouldnotcommit";
const branca = require("branca")(key);

const json = JSON.stringify({
    "iss" : "joe",
    "exp" : 1300819380,
    "http://example.com/is_root" : true
});

const token = branca.encode(json);
const payload = branca.decode(token);

console.log(token);
console.log(JSON.parse(payload));
```

Result is a 148 character token. However unlike the above JWT which is only
authenticated Branca token is also encrypted.

```text
4ghanLf33KQKBdEKvL5BpAUWXW6YzPbep54y9211upTQx7tzS2smFO5TWUw7PUdNvPh18
2FUIvQkZfp8kAk3XaE1xVQhhhApErJiIjgw4aC6gyOzmTwFvERIkkw2x2SLjvzHYjTA1f
7ihVL06Xh

{ iss: 'joe',
  exp: 1300819380,
  'http://example.com/is_root': true }
  ```

We can optimize this example a bit. Since Branca token has a timestamp in the header we can get rid of the `exp` claim. The example below uses `130081938` as timestamp just to demonstrate the token size. In reality timestamp should be the time when token was generated. Expiration is checked by the consumer when token is decoded.

```javascript
const key = "supersecretkeyyoushouldnotcommit";
const branca = require("branca")(key);

const json = JSON.stringify({
    "iss" : "joe",
    "http://example.com/is_root" : true
});

const token = branca.encode(json, 1300819380);
const payload = branca.decode(token, 3600); /* 3600 second ttl */

console.log(token);
console.log(JSON.parse(payload));
```

Now we are down to 125 characters but we still have all the features of the
original JWT.

```text
92FHUGUxd0EHJkHRnHtX1XuTHzJBzD2BHH0LhOWBWloRP5pmZ0TpGNUhBEMmjnm1ZpfB7
4Deba2xGshuewIpvWpGDP5xgOi8OAro7h79Lc10QPa7rtyWuYo76XzT

{ iss: 'joe', 'http://example.com/is_root': true }
```

We can still cut down the token size by using a binary serializer such as
[MessagePack](http://msgpack.org/) or [Protocol Buffers](https://developers.google.com/protocol-buffers/).
This does require more orchestrating though.

```javascript
const key = "supersecretkeyyoushouldnotcommit";
const branca = require("branca")(key);
const msgpack = require("msgpack5")();

const packed = msgpack.encode({
    "iss" : "joe",
    "http://example.com/is_root" : true
});

const token = branca.encode(packed);
const binary = branca.decode(token);
const payload = msgpack.decode(Buffer.from(binary));

console.log(token);
console.log(payload);
```

We are now down to 112 characters. Still authenticated and encrypted.

```text
1UhI0E8r3nNk5KbtxgbD9XwgTEKL6eBVILjfg5TTh71veZwMif4IAQSnvy8LG81CGR0uP
Pg75FNXvP7Lci6TJ3cK8b0ZxrNey4ItLIC9FdOiRRk

{ iss: 'joe', 'http://example.com/is_root': true }
```

## What About Macaroons?

Macaroons, Branca and JOSE are different things. JOSE is a standard
encoding for authenticated and optionally encrypted JSON payload. Branca is
a standard encoding for authenticated encryption for an arbitrary payload.

Macaroons are more abstract. There are no standard encodings or signing
algorithms. Macaroons are about delegating authorization. Holder of a macaroon
can pass on a subset of the given authority to a third party.

## Additional Reading

[Javascript Object Signing and Encryption is a Bad Standard That Everyone Should Avoid](https://paragonie.com/blog/2017/03/jwt-json-web-tokens-is-bad-standard-that-everyone-should-avoid) by Scott Arciszewski describes the problems in JOSE standard from a cryptographers point of view.

[Google's Macaroons in Five Minutes or Less](https://blog.bren2010.io/2014/12/04/macaroons.html) by Brendan Mc Million is the clearest no nonsense explanation if Macaroons I have seen.

[Using JSON Web Tokens as API Keys](https://auth0.com/blog/using-json-web-tokens-as-api-keys/) by Damian Schenkelman. Since the article mostly talks about payload all the examples can also be implemented with a Branca token.
