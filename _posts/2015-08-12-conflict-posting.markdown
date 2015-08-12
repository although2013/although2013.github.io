---
layout: post
title:  "Conflict posting"
date:   2015-08-12 16:40:43
categories: jekyll update
---

昨天有个家庭任务，就是如果两个用户同时编辑一篇文章，一个用户编辑好了提交，另一个用户也要提交，怎么解决这样的冲突和覆盖了他人的修改的问题呢?

我的第一个方法是在 model 中加一个 `version` 字段，表单中也加入一个 `hidden_field`
{% highlight ruby %}
<%= f.hidden_field :version %>
{% endhighlight %}

然后在 model 中添加一个自定义函数去验证：
{% highlight ruby %}
class Post < ActiveRecord::Base
  validate :check_version, on: :update

  def check_version
    if self.version_changed?
      errors.add(:version, "Someone has changed this before!")
    else
      self.version = self.version + 1
    end
  end
end
{% endhighlight %}

如果提交的`version`和数据库中的`version`不一致，就会报错，否则`version`自增1，存入数据库。 `version_changed?`也是一个内置函数（算是吧）。


第二天的时候看了一个 Railscast，结果发现 Rails 中已经内置了这种功能：  
`ActiveRecord::Locking::Optimistic`  
只需要在 Post 中添加一个字段名为 lock_version, 类型为 integer。
{% highlight ruby %}
class AddLockingColumnsToPost < ActiveRecord::Migration
  def change
    add_column :posts, :lock_version, :integer
  end
end
{% endhighlight %}
当发生编辑冲突时，就会 raise `ActiveRecord::StaleObjectError`, 然后去rescue就好了。

如果是只有这个资源会用到这种多用户编辑冲突保护的话，就直接在 controller 里 rescue:
{% highlight ruby %}
def update
  if @post.update(post_params)
    redirect_to @post, notice: 'Post was successfully updated.'
  else
    render :edit
  end
rescue ActiveRecord::StaleObjectError
  render :conflict  #render some view
end
{% endhighlight %}

如果希望复用，则可修改控制器中的 update 为：`@post.update_with_conflict(post_params)`  
然后在 model 定义这个方法（railscast 上的解决办法）:
{% highlight ruby %}
def update_with_conflict_validation(*args)
  update_attributes(*args)
rescue ActiveRecord::StaleObjectError
  self.lock_version = lock_version_was
  errors.add :base, "This record changed while you were editing it."
  changes.except("updated_at").each do |name, values|
    errors.add name, "was #{values.first}"
  end
  false 
end
{% endhighlight %}

首先调用 `update_attributes(*args)` 如果异常，进入 rescue。
`except(“updated_at”)` 就不显示更新时间的变化，也不输出 lock_version 的变化，其他的都只输出之前版本的值。

![screenshot]({{ site.url }}/images/Screen\ Shot\ 2015-08-12\ at\ 3.45.42\ PM.png)
Screen Shot 2015-08-12 at 3.45.42 PM.png

昨天晚上我还发现了个 gem 叫 `Diffy`，效果类似 GitHub 上的 Diff 页面，挺好看的。
不过好像是以`\n`作为换行符，而网页提交表单中换行使用`\r\n`，所以要把`\r\n`都替换成`\n`类似如下：
{% highlight ruby %}
class Post < ActiveRecord::Base
  validate :check_version, on: :update

  def check_version
    post = Post.find(self.id)
    text_before = (post.body + "\n").gsub("\r\n", "\n")
    text_after  = (self.body + "\n").gsub("\r\n", "\n")

    if self.version != post.version
      diff_msg = Diffy::Diff.new(text_before, text_after).to_s(:html)
      errors.add(:version, diff_msg)
    else
      self.version = self.version + 1
    end
  end
end
{% endhighlight %}

不确定这里的`Post.find` 是不是有方法能省去，感觉挺奇怪的。。