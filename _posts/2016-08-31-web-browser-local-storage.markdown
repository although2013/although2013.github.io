---
layout: post
title:  "Web Browser Local Storage"
date:   2016-08-31 09:13:02
categories: jekyll update
---

本文将介绍几种将数据存储在用户浏览器的方法，即 Cookie, Web Storage 和 IndexedDB，并简单介绍其使用方法与适用情景。

# Cookie

Cookie 通常被用来辨识多次请求是否由同一个用户发起，大小限制为 4KB，可携带的数据量最小，在每次请求中都会带上，因此过多使用也可能造成性能问题。  
Cookie 可以设置访问域，可以实现一个顶级域名下多个子域名共享数据。  
Cookie 可以设置 expire ，如果没有设置就是  session 级别，关闭浏览器后会清空（不是关闭标签页）。  
另外 Cookie 还可以设置 HTTPOnly，这会增强安全性，使 XSS 攻击成本更高。


{% highlight javascript %}
allCookies = document.cookie;  //不能访问到 HTTPOnly 的值
document.cookie = "favorite_food=tripe"; //添加cookie
document.cookie = "favorite_food=; expires=Thu, 01 Jan 1970 00:00:00 GMT"; //删除cookie
{% endhighlight %}


# Web storage
Web storage 分为两种，`session storage` 和 `local storage`，都是存储键值对，所有的值会被转成 String，所以如果存储对象需要提前将对象转换成 JSON 等格式在存储。

Session storage 的访问限制为当前页面，多个标签页之间不能互相访问，刷新页面不会消失，但关闭标签页就会清空。

Local storage 的访问限制与前者不同，local storage 可以在多个标签页之间互相访问和修改。它会被永久保存，除了用户清除浏览器本地数据或用JS来清除。

Web storage 都不能手动设置访问域，只能访问当前域名下的数据，每个域名的存储大小一般限制为 5M 个字符（JS 使用的 UTF-16 每个字符占用两字节）。具体可以在 [dev-test.nemikor.com](http://dev-test.nemikor.com/web-storage/support-test/) 测试你的浏览器是否支持 web storage 以及存储大小的限制。

除此之外，还可以通过 `StorageEvent` 来侦听 storage 的改变，可以影响所有打开的该网站的标签页，这里有个例子 [github.com/mdn/web-storage-demo](https://github.com/mdn/web-storage-demo)，但他的那个 live demo 好像有问题，没有引入 event.js，别的标签页不会立即改变，不过原理就是这样，可以在实现多个标签页之间通信。

需要注意的是 `StorageEvent` 并不会在当前页面触发，如果有其他打开着的同域名的标签页，它们就会触发 storage 事件（即只有原始页面不触发）。

Local storage 和 session storage 的 API 基本相同，这里就以 local storage 为例：

{% highlight javascript %}
localStorage.setItem("username", "John");
localStorage.getItem("username");

var obj = {'a': 1, 'b': 2};
localStorage.setItem('obj', JSON.stringify(obj));
JSON.parse(localStorage.getItem('obj'));

localStorage.removeItem('test'); // 删除 item
localStorage.clear();  // 清空
{% endhighlight %}

判断浏览器是否支持 local storage

{% highlight javascript %}
window.localStorage && window.localStorage.getItem
{% endhighlight %}

另外如果 local storage 存满了会触发异常，注意异常处理。

# Web SQL 和 IndexedDB

这两者堪称 web 存储中的航空母舰，当然使用方法也有一点复杂，Web SQL 已经不再积极开发，所以 IndexedDB 应该就代表了未来，可以在 [caniuse.com](http://caniuse.com/#search=indexeddb) 看到两者兼容性的对比。两者理论上都没有存储大小的限制。

在这里我们尝试来创建一个 `contacts` 的对象存储空间（`objectStore`），相当于关系型数据库的表，database 的名字就叫 dev 好了，`DB_VERSION` 是数据库版本号，用来判断是否需要升级当前已经持久化的数据库 。


{% highlight javascript %}
const DB_NAME = 'dev';
const DB_VERSION = 1;
const DB_STORE_NAME = 'contacts';

var db;
window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;

function openDb() {
  var req = indexedDB.open(DB_NAME, DB_VERSION);

  req.onsuccess = function (evt) {
    db = this.result;
  };

  req.onerror = function (evt) {
    console.error("openDb:", evt.target.errorCode);
  };

  // 定义数据结构
  req.onupgradeneeded = function (evt) {
    var db = evt.currentTarget.result;
    var store = db.createObjectStore(DB_STORE_NAME, { keyPath: 'id', autoIncrement: true });

    store.createIndex('name', 'name', { unique: false });
    store.createIndex('user_id', 'user_id', { unique: true });
  };
};

// 创建
openDb();
{% endhighlight %}


运行上面的短短几行代码后就创建好了 `contacts`，然后我们来添加一条数据：

{% highlight javascript %}
var request = db.transaction(["contacts"], "readwrite")
                .objectStore("contacts")
                .add({name: 'Ge Hao', user_id: '1'});
{% endhighlight %}


由于异步的原因如果想要删除某条记录，就需要使用回调：

{% highlight javascript %}
// 这个函数返回 objectStore
function store() {
  var tx = db.transaction('contacts', 'readwrite');
  return tx.objectStore('contacts');
}

var store = store();
var request = store.get(4);  // 假设通过某种查询获得一条数据
request.onsuccess = function(evt) {
  var record = evt.target.result;
  store.delete(record.id);
}
{% endhighlight %}

想要 update 一条数据可以使用 put ：

{% highlight javascript %}
request.onsuccess = function(event) {
  var data = event.target.result;
  data.name = 'yoyoyo';
  var requestUpdate = objectStore.put(data);
  requestUpdate.onsuccess = function(event) {
      // Success - the data is updated!
  };
};
{% endhighlight %}


更多的请前往 [mozilla.org/Using_IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB) 阅读，作为一个专职卖萌的后端工程师表示有点复杂。


参考资料：

[http://www.alloyteam.com/2012/04/sth-about-localstorage/](http://www.alloyteam.com/2012/04/sth-about-localstorage/)  
[https://segmentfault.com/a/1190000005927232](https://segmentfault.com/a/1190000005927232)  
[http://javascript.ruanyifeng.com/bom/webstorage.html](http://javascript.ruanyifeng.com/bom/webstorage.html)  
mdn  