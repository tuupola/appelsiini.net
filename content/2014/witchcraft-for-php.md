---
title: Witchcraft for PHP
date: 2014-10-18
tags:
    - PHP
photo: etienne-desclides-119070.jpg
---

There are two kinds of people. Those who like their accessors and mutators to start with `get` and `set`. This is also what PHP-FIG [seems to suggest](https://github.com/php-fig/fig-standards/blob/master/proposed/http-message.md).

```php
$unicorn = new Unicorn();
$unicorn->setBirthday("1930-24-12")->setColor("rainbow");
print $unicorn->getAge();
```

It works well with IDE autocompletion. It is also easy to write API documentation using PHPDoc. Then there are those like me who prefer to leave `get` and `set` out.

```php
$unicorn = new Unicorn();
$unicorn->birthday("1930-24-12")->color("rainbow");
print $unicorn->age();
```

<!--more-->

Or sometimes even access them as properties.

```php
$unicorn = new Unicorn();
$unicorn->birthday = "1930-24-12";
$unicorn->color = "rainbow";
print $unicorn->age;
```

### The usual way

You have your usual class with boilerplate accessors and mutators.

```php
class Unicorn
{
    private $color;
    private $birthday;

    public function __construct($color = "white", $birthday = null)
    {
        $this->color = $color;
        $this->birthday = $birthday;
    }

    public function getColor()
    {
        return $this->color;
    }

    public function setColor($color)
    {
        $this->color = $color;
        return $this;
    }

    public function getBirthday()
    {
        return $this->birthday;
    }

    public function setBirthday($birthday)
    {
        $this->birthday = DateTime::createFromFormat("Y-m-d", $birthday);
        return $this;
    }

    public function getAge()
    {
        $now = new DateTime();
        return $this->birthday->diff($now)->format("%y years");
    }
}
```

It all works really nice with ide autocompletes and everything. Problem is  code looks ugly. Yes, it is matter of taste. My taste might be different than yours.

 ```php
$unicorn = new Unicorn();
$unicorn->setBirthday("1930-24-12")->setColor("rainbow");
print $unicorn->getAge();
```

### Magic methods

[Witchcraft](https://github.com/tuupola/witchcraft) to the resque. It implements [opionated PHP magic methods as traits](https://github.com/tuupola/witchcraft). If you add `Witchcraft\MagicMethods` trait you can use pretty methods.

```php
class Unicorn
{
    use \Witchcraft\MagicMethods;

    private $color;
    private $birthday;

    ...
}

$unicorn = new Unicorn();
$unicorn->birthday("1930-24-12")->color("rainbow");
print $unicorn->age();
```

> **HEADS UP!** You still must write the boilerplate methods. Witchcraft just enables accessing them as properties.

### Magic properties

If you add `Witchcraft\MagicProperties` trait you can use pretty properties.

```php
class Unicorn
{
    use \Witchcraft\MagicProperties;

    private $color;
    private $owner;

    ...
}

$unicorn = new Unicorn();
$unicorn->birthday = "1930-24-12";
$unicorn->color = "rainbow";
print $unicorn->age;
```

> **HEADS UP!** You still must write the boilerplate methods. Witchcraft just enables accessing them as properties.

### Third party code

You can even use it with third party code. However it will work only if the library has properly implemented mutators and accessors. Let's take [League\Url](http://url.thephpleague.com/) as an example. I love it. It is just all the `get` and `set` which make my eyes bleed.

Example from League website looks like following.

```php
use League\Url\Url;

$url = Url::createFromUrl(
    "http://user:pass@www.example.com:81/path/index.php?query=toto+le+heros#top"
);

$query = $url->getQuery();
$query->modify(array("query" => "lulu l'allumeuse", "foo" => "bar"));
$query["sarah"] = "o connors";

$url->setScheme("ftp");
$url->setFragment(null);
$url->setPort(21);
$url->getPath()->remove("path/index.php");
$url->getPath()->prepend("mongo db");
echo $url . PHP_EOL;

/* ftp://user:pass@www.example.com:21/mongo%20db?query=lulu%20l%27allumeuse&foo=bar&sarah=o%20connors */
```

To use Witchcraft I extend the original class and add the traits.

```php
use League\Url\Url;

Class MagicUrl extends Url
{
    use \Witchcraft\MagicMethods;
    use \Witchcraft\MagicProperties;
}
```

With magic in place above example code can become like below.

```php
$url = MagicUrl::createFromUrl(
    "http://user:pass@www.example.com:81/path/index.php?query=toto+le+heros#top"
);

$query = $url->query();
$query->modify(array("query" => "lulu l'allumeuse", "foo" => "bar"));
$query["sarah"] = "o connors";

$url->scheme("ftp");
$url->fragment(null);
$url->port(21);
$url->path->remove("path/index.php");
$url->path->prepend("mongo db");
echo $url . PHP_EOL;

/* ftp://user:pass@www.example.com:21/mongo%20db?query=lulu%20l%27allumeuse&foo=bar&sarah=o%20connors */
```

> **WARNING!**  Use Witchcraft on third party code only if you know what you are doing. It can break things. For example when the library already uses magic methods. Check the source first.

### Install

You can install latest version using [composer](https://getcomposer.org/). You can also find the [source in GitHub](https://github.com/tuupola/witchcraft).

```text
$ composer require tuupola/witchcraft
```
