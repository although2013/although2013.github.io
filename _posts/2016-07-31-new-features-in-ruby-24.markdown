---
layout: post
title:  "New Features in Ruby 2.4"
date:   2016-07-31 22:48:51
categories: jekyll update
---

本文翻译自 [blog.blockscore.com/new-features-in-ruby-2-4](https://blog.blockscore.com/new-features-in-ruby-2-4)


===

本文介绍了Ruby 2.4 一些新特性：  
 - 新增 Regexp#match? 方法  
 - 新增 Enumerable#sum 方法  
 - Dir 和 File 的新方法 empty?  
 - 新方法 Regexp#named_captures  
 - 新方法 Integer#digits  
 - Logger 接口改进  
 - OptionParse语法改进  
 - Array 也有了 #min 和 #max  
 - 精简数字类型（Bignum，Fixnum）  
 - :capacity 指定新建字符串的内存大小  
 - 修改 Symbol 的 #match 返回值  





===

# 超级快的 `Regexp#match?` 方法

Ruby 2.4 给正则表达式添加了新的 `#match?` 方法，它比任何的 Regexp 方法都快（三倍以上）。
当你使用 `Regexp#===`、`Regexp#=~` 或 `Regexp#match`时，Ruby 会创建 `$~` 这个全局变量来存放返回的 MatchData ：
{% highlight ruby %}
/^foo (\w+)$/ =~ 'foo bar'      # => 0
$~                              # => #<MatchData "foo bar" 1:"bar">

/^foo (\w+)$/.match('foo baz')  # => #<MatchData "foo baz" 1:"baz">
$~                              # => #<MatchData "foo baz" 1:"baz">

/^foo (\w+)$/ === 'foo qux'     # => true
$~                              # => #<MatchData "foo qux" 1:"qux">
{% endhighlight %}

我们的这个 `Regexp#match?` 返回 boolean，避免了生成一个 MatchData 对象或更新全局状态（or updating global state 应该是指避免了更新 `$~` 这个全局变量的意思吧）：

{% highlight ruby %}
/^foo (\w+)$/.match?('foo wow') # => true
$~                              # => nil
{% endhighlight %}

跳过了 `$~` 这个全局变量，Ruby 也就可以避免给 MatchData 去分配内存了。



---

# Enumerable 的新方法 `#sum`

可以在任意一个 `Enumerable` 对象上调用 `#sum`：
{% highlight ruby %}
[1, 1, 2, 3, 5, 8, 13, 21].sum # => 54
{% endhighlight %}
这个方法有一个可选参数，默认为0，这是该求和方法的初始值，所以 `[].sum` 的结果为 0。

如果你在非integer的array上面调用这个方法，那么你就需要提供一个初始值了：
{% highlight ruby %}
class ShoppingList
  attr_reader :items

  def initialize(*items)
    @items = items
  end

  def +(other)
    ShoppingList.new(*items, *other.items)
  end
end

eggs   = ShoppingList.new('eggs')          # => #<ShoppingList:0x007f952282e7b8 @items=["eggs"]>
milk   = ShoppingList.new('milks')         # => #<ShoppingList:0x007f952282ce68 @items=["milks"]>
cheese = ShoppingList.new('cheese')        # => #<ShoppingList:0x007f95228271e8 @items=["cheese"]>

eggs + milk + cheese                       # => #<ShoppingList:0x007f95228261d0 @items=["eggs", "milks", "cheese"]>
[eggs, milk, cheese].sum                   # => #<TypeError: ShoppingList can't be coerced into Integer>
[eggs, milk, cheese].sum(ShoppingList.new) # => #<ShoppingList:0x007f9522824cb8 @items=["eggs", "milks", "cheese"]>
{% endhighlight %}
最后一行的 `ShoppingList.new` 就是提供给 `sum` 的初始值了。



---

# Dir 和 File 模块的新方法 `empty?`

{% highlight ruby %}
Dir.empty?('empty_directory')      # => true
Dir.empty?('directory_with_files') # => false

File.empty?('contains_text.txt')   # => false
File.empty?('empty.txt')           # => true
{% endhighlight %}

`File.empty?` 等同于 `File.zero?`（后者在所有受支持的 Ruby 版本中都可用）。

目前`empty?`方法还不能用在 `Pathname` 上。



---

# 把已命名的匹配部分抽离出来 `Regexp#named_captures`

Ruby 2.4 中你可以用 `#named_captures` 方法把正则表达式中已命名的部分抽出来，放进一个 Hash 中：

{% highlight ruby %}
pattern  = /(?<first_name>John) (?<last_name>\w+)/
pattern.match('John Backus').named_captures # => { "first_name" => "John", "last_name" => "Backus" }
{% endhighlight %}

Ruby 2.4 还增加了 `#values_at` 方法，用他可以生成一个只包含你想要的部分的数组：

{% highlight ruby %}
pattern = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
pattern.match('2016-02-01').values_at(:year, :month) # => ["2016", "02"]
{% endhighlight %}



---

# 新方法 Integer#digits
{% highlight ruby %}
123.digits                  # => [3, 2, 1]
123.digits[0]               # => 3

# Ruby 2.3 你只能这样
123.to_s.chars.map(&:to_i).reverse # => [3, 2, 1]
{% endhighlight %}

注意数组的0是最右边（个位上）的数字。
即使是非十进制的数字，也只需要传递一个参数，如下是16进制：

{% highlight ruby %}
0x7b.digits(16)                                # => [11, 7]
0x7b.digits(16).map { |digit| digit.to_s(16) } # => ["b", "7"]
{% endhighlight %}



---

# 改进 `Logger` 接口

Ruby 2.3:
{% highlight ruby %}
logger1 = Logger.new(STDOUT)
logger1.level    = :info
logger1.progname = 'LOG1'

logger1.debug('This is ignored')
logger1.info('This is logged')

# >> I, [2016-07-17T23:45:30.571508 #19837]  INFO -- LOG1: This is logged
{% endhighlight %}
Ruby 2.4 把配置部分放在了构造函数中：
{% highlight ruby %}
logger2 = Logger.new(STDOUT, level: :info, progname: 'LOG2')

logger2.debug('This is ignored')
logger2.info('This is logged')

# >> I, [2016-07-17T23:45:30.571556 #19837]  INFO -- LOG2: This is logged
{% endhighlight %}




---

# 改进 `OptionParse` 使得生成Hash的语法更加简洁
Ruby 2.3 中，如果你希望把传入的参数都放入一个 Hash 中，你需要这样：
{% highlight ruby %}
require 'optparse'
require 'optparse/date'
require 'optparse/uri'

config = {}

cli =
  OptionParser.new do |options|
    options.define('--from=DATE', Date) do |from|
      config[:from] = from
    end

    options.define('--url=ENDPOINT', URI) do |url|
      config[:url] = url
    end

    options.define('--names=LIST', Array) do |names|
      config[:names] = names
    end
  end
{% endhighlight %}

Ruby 2.4 你可以使用参数 `:into` 来实现：

{% highlight ruby %}
require 'optparse'
require 'optparse/date'
require 'optparse/uri'

cli =
  OptionParser.new do |options|
    options.define '--from=DATE',    Date
    options.define '--url=ENDPOINT', URI
    options.define '--names=LIST',   Array
  end

config = {}

args = %w[
  --from  2016-02-03
  --url   https://blog.blockscore.com/
  --names John,Daniel,Delmer
]

cli.parse(args, into: config)

config.keys    # => [:from, :url, :names]
config[:from]  # => #<Date: 2016-02-03 ((2457422j,0s,0n),+0s,2299161j)>
config[:url]   # => #<URI::HTTPS https://blog.blockscore.com/>
config[:names] # => ["John", "Daniel", "Delmer"]
{% endhighlight %}




---

# Array 也有了 `#min` 和 `#max`
并且比 `Enumerable` 快一点（好吧。。）



---

# 精简了 Integers
Ruby 2.4 中你不再需要管理众多的数字类型：
{% highlight ruby %}
# Find classes which subclass the base "Numeric" class:
numerics = ObjectSpace.each_object(Module).select { |mod| mod < Numeric }

# In Ruby 2.3:
numerics # => [Complex, Rational, Bignum, Float, Fixnum, Integer, BigDecimal]

# In Ruby 2.4:
numerics # => [Complex, Rational, Float, Integer, BigDecimal]
{% endhighlight %}

`Fixnum` 和 `Bignum` 现在全都指向 `Integer`

{% highlight ruby %}
Fixnum  # => Integer
Bignum  # => Integer
Integer # => Integer
{% endhighlight %}




---

# :capacity 指定 String 的内存大小
{% highlight ruby %}
template  = String.new(capacity: 100_000)
{% endhighlight %}



---

# Symbol 的`#match`与 String 表现不一致

Ruby 2.3 的 Symbol#match 返回匹配的位置（index），而 String#match 返回值是 MatchData 。现在统一返回 MatchData 。

{% highlight ruby %}
# Ruby 2.3 behavior:

'foo bar'.match(/^foo (\w+)$/)  # => #<MatchData "foo bar" 1:"bar">
:'foo bar'.match(/^foo (\w+)$/) # => 0

# Ruby 2.4 behavior:

'foo bar'.match(/^foo (\w+)$/)  # => #<MatchData "foo bar" 1:"bar">
:'foo bar'.match(/^foo (\w+)$/) # => #<MatchData "foo bar" 1:"bar">
{% endhighlight %}
