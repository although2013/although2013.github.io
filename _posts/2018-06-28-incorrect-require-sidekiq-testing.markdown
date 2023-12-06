---
layout: post
title:  "Incorrect require sidekiq testing"
date:   2018-06-28 06:12:06
categories: jekyll update
---


在系统中有一个 sidekiq worker 被定义成在 order 创建成功后的30分钟执行：

{% highlight ruby %}
PaytimeExpiredWorker.perform_in(1800, id)
{% endhighlight %}

在 `test_helper` 中我们 `require 'sidekiq/testing'` 这会默认使用 `Sidekiq::Testing.fake!` 它会使用 ruby Array 来作为队列运行 worker，原本应该30分钟后才执行的任务也被立即执行了，造成 order 状态被改成已过期，使测试失败。

另外一个问题默认 fake 模式下，单个 test 执行却能够成功运行

```
bin/rails test test/models/discount_code_test.rb:155
```

造成这个的原因是 `require 'sidekiq/testing'` 没有写在被所有 tests require 的 test_helper.rb 文件中，而只在某些测试文件中require，
如下面的代码片段来自 test/integration/api/v1/coupons_controller_test.rb 文件

{% highlight ruby %}
require 'test_helper'
require 'sidekiq/testing'

class Api::V1::CouponsControllerTest < ActionDispatch::IntegrationTest

  def setup
    Sidekiq::Testing.inline!

...
{% endhighlight %}