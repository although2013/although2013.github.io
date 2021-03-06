---
layout: post
title:  "Reading Notes"
date:   2015-09-23 20:11:33
categories: jekyll update
---

这些时间在读《松本行弘的程序世界》，看到里面有关于字符串，编码和正则式等，有挺多是之前不知道的。

# sort 与 sort_by 区别

{% highlight ruby %}
ary.sort do |a,b|
  a.to_i <=> b.to_i
end
{% endhighlight %}

`sort`每次都会执行块处理，如上面的代码，每次比较都要进行整数转换，比较浪费资源，而且不是线性增长的。  
`sort_by`用执行块的代码所生成的结果进行排序，对每个元素只执行一次块的调用。但会占用更多的内存：`ary.sort_by{|x| x.to_i}`


# Encoding
Unicode 5.0 已经收入9万多字，已经超出了65536的范围。  
UTF-8 作为可变长的，与 ASCII 具有兼容性的字符编码方式。将 ASCII 字符串当做 UTF-8 字符串来处理也不会有问题。  

几乎多有情况下，文本数据都不附带文字编码方式的信息，所以容易引起错误。  
使用 UCS 方式的编程语言会在输入输出时对文本做统一处理。  
Ruby 使用 CSI，不会对文本做任何处理，成为少有的例外。  



# Regex
 - 后面跟一个`?`就会进行懒惰匹配（第一次与模式匹配时就停止检索）。  
 - `(.)\1`是指匹配两个相同的字符，在后面使用匹配的字符串称为向后引用。  
 - `|`与其他正则表达式元素比，优先级要低，`yes|no`会解释为`yes`或者`no`（不同于`ye(s|n)o`的匹配结果）。  
 - 匹配文件路径时会有很多的`/`要转义，即要写成`\/`，使用`%r{}`可以避免，`{}`可以换成别的，成对出现就可：`%r!/usr(/local)?/bin!`。  
 - `$&` 最后的匹配字符串  
 - $` 位于匹配前的字符串  
 - `$'` 位于匹配后的字符串  
 - `$+` 匹配最后括号的字符串  
 - `$n` 匹配第n个括号内的字符串  
 - `\&`或`\0` 整个匹配部分的字符串  

{% highlight ruby %}
"a,b:c".split(/[:,]/)
#=> ["a", "b", "c"]

#匹配html标签
str.split(/<.*?>/)   #=>不包括html标签
str.split(/(<.*?>)/) #=>返回的数组中包含html标签
{% endhighlight %}

# RSA
（后来我认真搜了一下发现还是有一些数学理论的，感觉要自己写代码生成密钥还是挺复杂的）  
这是一个RSA加密的小程序，  
现实中pq的长度为1024位（二进制），这里并不考虑效率  
(pq, e) 为公钥，(pq, d) 为私钥  
p,q为两个素数

{% highlight ruby %}
pq = p * q
k = n * (p - 1) * (q - 1) + 1
n为任意正数
e, d 能使 e*d = k


def rsa(pq, k, mesg)
  mesg.collect do |x|
    x**k%pq
  end
end


orig = [7, 13, 17, 24]
encode = rsa(33, 3, orig)
#=> [13, 19, 29, 30]
decode = rsa(33, 7, encode)
#=> [7, 13, 17, 24]
{% endhighlight %}
