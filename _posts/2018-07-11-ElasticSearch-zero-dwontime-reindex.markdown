---
layout: post
title:  "ElasticSearch zero-dwontime reindex"
date:   2018-07-11 09:46:57
categories: jekyll update
---

将数据库中的所有数据重新导入 elasticsearch 比较慢，即使使用 bulk api 批量导入也可能要花上 5 - 10 分钟，所以我尝试使用 ES 的 alias 来尽可能减少停机的时间。

需要注意的是，我的实现主要针对数据量不是特别大，并且没有不间断的创建和更新操作的情况。更新很频繁这种情况我会在最后简单讨论一下。

本文基于 Ruby on Rails 开发环境，并使用 `elasticsearch-rails` 这个 gem。

### 简单情况下的 zero-downtime

通常情况下我们会生成和数据库表名相同的 ES 索引名，在这里我用商品 `products` 作为示例，ElasticSearch 的 alias 就是别名，使用它来实现不停机重建索引的步骤如下：


#### 1. 使用当前时间创建一个新的索引，导入数据

```ruby
@date = Time.now.strftime '%Y%m%d%H%M%S'
@alias_name = "#{Product.index_name}_#{@date}"

# 将数据导入 @alias_name 这个索引中
Product.import(force: true, index: @alias_name, type: Product.document_type)
```

这里生成的 `@alias_name` 格式是 `products_20180711172532` 这样的。

#### 2. 将别名关联到刚才生成的索引上

这里还要注意，如果之前没有使用过 alias 别名，那么你的索引名就是 `products`，应该将其删除。
```ruby
# 如果存在名为 products 的索引，则将其删除
client.indices.delete index: Product.index_name rescue nil
# 将别名 products 关联到索引 products_20180711172532 上去
client.indices.put_alias index: @alias_name, name: Product.index_name
```

#### 3. 将之前关联的旧索引删除

我们需要把 products 这个别名所关联的其他索引都删掉，不然搜索结果中会包含两个索引中的结果
```ruby
aliases = client.indices.get_alias(index: 'products').keys
# 该方法对应 GET http://localhost:9200/products/_alias
#
# 返回的 aliases 格式如下
# {"products_20180711143627"=>{"aliases"=>{"products"=>{}}}, "products_0711_17_09_26"=>{"aliases"=>{"products"=>{}}}}
```

需要注意这里使用的是 `get_alias`，Elasticsearch 在 6.0 版本有一些 break changes，可以在这里查看：[break_changes_60](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking_60_rest_changes.html)，在 6.0 之前版本应该可以使用 `get_aliases` 方法（对应 `GET products/_aliases`）。

好了，这样就完成了整个索引重建工作，把这些结合起来的代码看起来应该就是下面这样：

```ruby
class Reindex
  def initialize(klass_name)
    raise 'unknow class name' unless klass_name
    @klass = klass_name.constantize
    @date = Time.now.strftime '%Y%m%d%H%M%S'
    @alias_name = "#{@klass.index_name}_#{@date}"
  end

  def reindex
    import
    put_alias
    delete_old_aliases
  end

  def put_alias
    client.indices.delete index: @klass.index_name rescue nil
    client.indices.put_alias index: @alias_name, name: @klass.index_name
  end

  def delete_old_aliases
    aliases = client.indices.get_alias(index: @klass.index_name).keys

    aliases.each do |alias_name|
      unless alias_name == @alias_name
        client.indices.delete(index: alias_name)
        puts "Deleted #{alias_name}"
      end
    end
  end

  def import_documents
    @klass.import(force: true, index: @alias_name, type: @klass.document_type)
  end

  private

  def client
    @client ||= @klass.__elasticsearch__.client
  end
end

# 粗暴一点的使用方法就是直接 Reindex.new('Product').reindex
# 如果是线上环境还是要谨慎一些
```

### 增量式的数据

有时候我们的数据会不断增加或者频繁地更新（比如服务器 log），那么使用上面这种方法就不可行了，根据我 google 的一些方案来看，比较可行的是在 Redis 中设置一个锁，锁开启后就将后续的 ES 操作按照 bulk 更新的 json 格式存在 Redis 中，在旧数据迁移之后再按照存在 Redis 中 ES 指令进行批量更新，最后关闭这个锁。

然而如果是重新使用数据库数据进行导入的话，还是会存在不一致，除非这个锁把数据库的各种操作也给锁了，所以这样实现起来还是比较困难的，我目前也没有这样的需求场景，就略过了。


### 参考

- [https://github.com/elastic/elasticsearch-rails]()
- [http://blog.ryanjhouston.com/2017/04/12/elasticsearch-zero-downtime-reindexing.html]()
- [https://www.elastic.co/blog/changing-mapping-with-zero-downtime]()
- [https://gist.github.com/simonmorley/5901be947407ea427f0a]()