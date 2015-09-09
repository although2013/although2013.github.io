---
layout: post
title:  "Data racing in validation"
date:   2015-09-09 18:48:03
categories: jekyll update
---

其实，这还是个家庭作业 `,,Ծ‸Ծ,,`

看了这篇文章[race-conditions-with-duplicate-unique-keys][unique-keys]，讲的是 validation 在 rails 层面和 mysql 层面的差别，

如果在 migration 中加入了 unique index，应该是不会产生重复数据的，

而 model 中的验证可能会因为：  
用户双击了提交按钮；直接在db中插入数据；非常多的用户同时提交等原因造成重复数据吧，

目前是这么理解的，如果不对欢迎打脸：althoughghgh@gmail.com



[unique-keys]: http://makandracards.com/makandra/13901-understand-and-fix-race-conditions-with-duplicate-unique-keys-in-rails-mysql