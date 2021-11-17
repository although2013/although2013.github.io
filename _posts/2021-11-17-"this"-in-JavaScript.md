---
layout: post
title:  "\"this\" in JavaScript"
date:   "2021-11-17 14:20:43 +0900"
categories: jekyll update
---

原文： [understanding-javascript-function-invocation-and-this](https://yehudakatz.com/2011/08/11/understanding-javascript-function-invocation-and-this/)


# 核心原语

1. 创建一个参数列表 `argList`，包含了所有传入的参数
2. 第一个参数是 `thisValue`
3. 调用函数时把 `this` 设置为 `thisValue`，并传入 `argList`

例如：
```javascript
function hello(thing) {
  console.log(this + " says hello " + thing);
}

hello.call("Yehuda", "world") //=> Yehuda says hello world
```

# 函数的简单调用
像上面这样每次都使用 `call` 来调用函数有点烦人，JavaScript允许我们直接使用括号 `hello("world")` 这样的语法。

```javascript
function hello(thing) {
  console.log("Hello " + thing);
}

// this:
hello("world")

// desugars to:
hello.call(window, "world");
```

但这个行为在ECMAScript 5的严格模式中有所不同[2]：
```javascript
// this:
hello("world")

// desugars to:
hello.call(undefined, "world");
```
> The short version is: **a function invocation like `fn(...args)` is the same as `fn.call(window [ES5-strict: undefined], ...args)`.**

[2] 实际上是所有情况下都会传入 `undefined` ，但是在非严格模式时，函数会把这个值改为 `thisValue` 。

# 成员函数
```javascript
var person = {
  name: "Brendan Eich",
  hello: function(thing) {
    console.log(this + " says hello " + thing);
  }
}

// this:
person.hello("world")

// desugars to this:
person.hello.call(person, "world");
```
上面的 `hello` 是独立函数，再来看下面的动态添加函数到 `person` 对象上。
```javascript
function hello(thing) {
  console.log(this + " says hello " + thing);
}

person = { name: "Brendan Eich" }
person.hello = hello;

person.hello("world") // still desugars to person.hello.call(person, "world")

hello("world") // "[object DOMWindow]world"
```
这个时候 `hello` 的 `this` 会根据调用方法的不同而变化。

# 使用 `Function.prototype.bind`

```javascript
var person = {
  name: "Brendan Eich",
  hello: function(thing) {
    console.log(this.name + " says hello " + thing);
  }
}

var boundHello = function(thing) { return person.hello.call(person, thing); }

boundHello("world");
```
这里我们调用的 `boundHello("world");` 会被 **脱糖** 成 `boundHello.call(window, "world")` （可以看上一个例子），但是我们使用 call 方法重新将 this 修改成了person，所以 console 中会打印出 `Brendan Eich says hello world` 。

我们可以让这个技巧更加通用：
```javascript
var bind = function(func, thisValue) {
  return function() {
    return func.apply(thisValue, arguments);
  }
}

var boundHello = bind(person.hello, person);
boundHello("world") // "Brendan Eich says hello world"
```
让我们来理解这段代码，
1. arguments 是一个类似 Array（但不是 Array）的参数列表，包含所有传入的参数。
2. apply 和 call 基本相同，他可以接受参数列表（Array-like）而不需要一个一个列出来
3. bind 方法返回一个函数，这个 boundHello 被调用时会设置 this 并使用传入的参数

因为这是一个有点常见的习惯用法，所以 ES5 引入了 `bind` 在所有的 `Function` 对象上，来实现下面的用法

```javascript
var boundHello = person.hello.bind(person);
boundHello("world") // "Brendan Eich says hello world"
```
例如：
```javascript
var person = {
  name: "Alex Russell",
  hello: function() { console.log(this.name + " says hello world"); }
}

$("#some-div").click(person.hello.bind(person));

// when the div is clicked, "Alex Russell says hello world" is printed
```