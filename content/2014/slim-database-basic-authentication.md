---
title: HTTP Basic Authentication from Database for Slim
date: 2014-11-05
tags:
    - PHP
photo: james-sutton-187816.jpg
---

[HTTP Basic Authentication middleware](https://github.com/tuupola/slim-basic-auth) comes with simple PDO authenticator. It can be used to authenticate users from database. Authenticator assumes username and hashed password are stored in database. Default name for database table is <code>users</code>. Default column names for username and hash are unsurprisingly <code>user</code> and <code>hash</code>. Column and table names can also be set in options. Hash must be created with `password_hash()`  function. Simplest possible table to store user data looks something like this.

```sql
CREATE TABLE users (
    user VARCHAR(32) NOT NULL,
    hash VARCHAR(255) NOT NULL
)
````

<!--more-->

You can then insert an user with following.

```php
$user = "root";
$hash = password_hash("t00r", PASSWORD_DEFAULT);

$status = $pdo->exec(
    "INSERT INTO users (user, hash) VALUES ('{$user}', '{$hash}')"
);
```

With some users in database you can use them in basic auth.

```php
use \Slim\Middleware\HttpBasicAuthentication\PdoAuthenticator;

$pdo = new \PDO("sqlite:/tmp/users.sqlite");

$app = new \Slim\Slim();

$app->add(new \Slim\Middleware\HttpBasicAuthentication([
    "path" => "/admin",
    "realm" => "Protected",
    "authenticator" => new PdoAuthenticator([
        "pdo" => $pdo
    ])
]));
```

### Different database naming

To override default table and column names you can pass them in options.

```php
$app->add(new \Slim\Middleware\HttpBasicAuthentication([
    "path" => "/admin",
    "realm" => "Protected",
    "authenticator" => new PdoAuthenticator([
        "pdo" => $pdo,
        "table" => "accounts",
        "user" => "username",
        "hash" => "hashed"
    ])
]));
```

### Install

You can install latest version using [composer](https://getcomposer.org/). Source is [in GitHub](https://github.com/tuupola/slim-basic-auth).

```text
$ composer require tuupola/slim-basic-auth
```