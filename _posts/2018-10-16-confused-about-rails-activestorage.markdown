---
layout: post
title:  "Confused about rails ActiveStorage"
date:   2018-10-16 14:40:43
categories: jekyll update
---

这两天试用了 ActiveStorage，遇到了一些小问题记录一下

## HTML5 Video 无法快进到指定位置
我用 activestorage 来存储上传的视频文件，前端试用 html5 的 video 标签来展示，结果发现点击视频进度条无法快进到指定位置。经过各种搜索发现 Rails 项目上有一些 Issue 已经报告了这个问题

- https://github.com/rails/rails/issues/33368
- https://github.com/rails/rails/issues/32193

解决方法：我的是个人项目，就直接在 Gemfile 中指定 rails 使用 master 分支。

## service_url 自动过期，返回 404

ActiveStorage 生成的连接会过期，默认是 5 分钟，可以通过 `config.active_storage.service_urls_expire_in` 来自定义过期时间。
文档参考： https://edgeguides.rubyonrails.org/configuring.html#configuring-active-storage
