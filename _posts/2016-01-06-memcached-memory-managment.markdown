---
layout: post
title:  "Memcached Memory Managment"
date:   2016-01-06 23:52:01
categories: jekyll update
---

最近看了一篇关memcached内存分配的文章，大部分memcached 的操作都是O(1)的，包括set, add, get, flush等，在你使用memcached之前，你得告诉它它可以使用的内存大小为多少，然后他会一次性占用这些内存，并使用自己的内存管理方法——slab allocator来管理这些内存（因为频繁向操作系统申请内存是十分低效的）。

这一块内存会被分为若干个`page`，每个`page`都是`1MB`大小。  
每个`page`会被分成若干`chunk`，同一个`page`中所有的`chunk`都是相同大小的。  
最小的`chunk`是80KB，然后依次以大约1.25倍的倍数增大，分别是100KB，128KB，160KB...直到1MB，所以有些`page`可能只有一个`chunk`(1个1MB大小的chunk)。  
所有相同`chunk`大小的`page`们可以被归为一个`slab-class`，一个`slab-class`下可以有多个`page`。  
但初始化时，每种`slab-class`都只生成一个`page`，等到某种`slab-class`的`page`被填满了，再从内存池里取出一个`page`，切成同样的`chunk`大小，取第一个`chunk`填入数据。

用着用着，分配的整个内存池都被用完了，如果这时又有新的数据想要被缓存，怎么办呢，这时memcached会用到LRU（Least Recently Used）算法去删除某个`chunk`的内容，给这个新的数据腾出空间。那么应该删除哪个`chunk`呢？是占用空间最大的那个，还是我们最早存储的那个呢？都不是，实际上，每个存入`chunk`的对象都有一个counter，这个counter存的是一个时间戳，每次我们使用了一个`chunk`中的数据时，都会把这个`chunk`的时间戳更新为当前时间，当内存用完，我们会把更新时间最久远的那个`chunk`中的数据删除，并填入新数据。

需要注意的是，每个`slab-class`都使用自己的LRU，也就是说，当整个内存池用完，这时来了一个120KB的数据，计算后发现128KB大小的`chunk`最合适（最接近120KB大小），然后就会找出128KB对应的`slab-class`的所有`page`的所有`chunk`中更新时间最久的`chunk`，把它的数据替换掉。即使可能有一个256KB的`chunk`的更新时间更加久远。

### consistent hashing
一致性哈希，对每个要存入的对象进行哈希，取前四位，当作是16进制的数字，于是对象的哈希值会落在0~65536之间，就像0~12个小时一样围成一个圈，如果你有多台server，给每个server100个点，均匀分布在这个圆圈上，约定对象按某一方向（如逆时针）存入最近的点所属的server上，这样，当某台server挂了，只有少部分的缓存不可访问，大部分缓存仍然可以在逆时针最近的服务器上被访问到。

### LRU
LRU算法的实现使用到了双向链表和哈希表

{% highlight java %}
//double linked list node
class Node {
    int key;
    int value;
    Node pre;
    Node next;

    public Node(int key, int value) {
        this.key = key;
        this.value = value;
    }
}
{% endhighlight %}
还有两个指针，分别为head和tail，添加和删除Node的时候只需要更改4个指针的指向，不需要移动元素O(1)，另外还有一个hash table来保证get Node的操作也是O(1)。