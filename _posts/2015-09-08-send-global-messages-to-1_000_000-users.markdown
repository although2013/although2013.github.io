---
layout: post
title:  "Send Global Messages to 1_000_000 Users"
date:   2015-09-08 21:55:59
categories: jekyll update
---

同样，这也是个家庭作业，目的是向所有的注册用户发送一封站内信。

比较简单的方法就是建一个`messages`表，插入一条站内信，然后每个用户（User）有一个信箱（Inbox），
向所有用户的信箱中插入一条记录：`:message_id => 1, :user_id => 1, :is_read => false`。

如果用户有很多的话，就会花上很多的时间了。

比较暴力的解决办法我觉得有：为全站消息单独建一个表，然后User查询信箱时先查询全站消息表，
但是这样就没有办法判断某个用户是否已经读过某条全站消息了。

我的办法呢，使用 redis 的 bitmap，用户读过就把这条全站消息对应的用户 id 位置设置为1:
`$redis.setbit("gmsg#{msg_id}", 45656, 1)`

这个 `setbit` 的速度还是很快的，大概没有超过100微秒吧，另外 bitmap 有个限制就是不能超过2^32(512MB）。

{% highlight ruby %}
  <% @messages.each do |msg| %>
    <%= $redis.getbit("gmsg#{msg.id}", @user.id) %><br>
    <%= "#{msg.title} : #{msg.body}" %><br><br>
  <% end %>
{% endhighlight %}

哦对了，因为搞了100万用户，controller 里记得不要`User.all`了。。


下面是在 mysql 生成100万用户的 ruby 脚本，生成的时间大概两分钟。。换了几个写法好像都差不多花110秒左右，在我的小电脑上，换用 mysql 和 mysql2 这两个 gem 也差不多。

{% highlight ruby %}
require 'mysql'

con = Mysql.new 'localhost', 'root', '', 'domain_noti_development'

start_transaction = "START TRANSACTION;"
commit = "COMMIT;"

con.query start_transaction

for id in 1..1_000_000

  name = "\'user-#{id}\'"
  email = "\'although#{id}@gmail.com\'"
  created_at = updated_at = Time.now

  con.query "insert into users (id, name, email, created_at, updated_at) values\
            (#{id}, #{name}, #{email}, \'#{created_at}\', \'#{updated_at}\');"
end

con.query commit

con.close
{% endhighlight %}


另外还遇到一个 “Mysql Server has gone away” 的错误，修改my.cnf  
 - wait_timeout 尽可能大，  
 - max_allowed_packet = 128M（尽可能大）  
以及（可能需要）在 ruby 脚本中设置timeout：
{% highlight ruby %}
client = Mysql2::Client.new(
  :host => 'localhost',
  :username => 'root',
  :password => '',
  :database => 'domain_noti_development',
  :encoding => 'utf8',
  :read_timeout => 600,
  :write_timeout => 600,
  :connect_timeout => 600,
  :reconnect => true
)
{% endhighlight %}

my.cnf 可能在这些地方:
{% highlight c %}
/etc/my.cnf
/etc/mysql/my.cnf
/var/lib/mysql/my.cnf
...
{% endhighlight %}