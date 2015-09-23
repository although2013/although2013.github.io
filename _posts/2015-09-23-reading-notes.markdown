---
layout: post
title:  "Reading notes"
date:   2015-09-23 20:11:33
categories: jekyll update
---

这些时间在读《松本行弘的程序世界》，看到里面有关于字符串，编码和正则式等，有挺多是之前不知道的。

#sort 与 sort_by 区别
```
ary.sort{|a,b|
  a.to_i <=> b.to_i
}
```
sort 每次都会执行块处理，如上面的代码，每次比较都要进行整数转换，比较浪费资源，而且不是线性增长的。
sort_by 用执行块的代码所生成的结果进行排序，对每个元素只执行一次块的调用。
```
ary.sort_by{|x| x.to_i}
```
