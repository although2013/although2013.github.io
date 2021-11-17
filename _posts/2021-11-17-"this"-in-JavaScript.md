---
layout: post
title:  "\"this\" in JavaScript"
date:   "2021-06-22 14:00:43 +0900"
categories: jekyll update
---

原文： [understanding-javascript-function-invocation-and-this](https://yehudakatz.com/2011/08/11/understanding-javascript-function-invocation-and-this/)

## 核心原语

1. 创建一个参数列表`argList`，包含了所有传入的参数
2. 第一个参数是`thisValue`
3. 调用函数时把`this`设置为`thisValue`，并传入`argList`

例如：
```javascript
function hello(thing) {
  console.log(this + " says hello " + thing);
}

hello.call("Yehuda", "world") //=> Yehuda says hello world
```
