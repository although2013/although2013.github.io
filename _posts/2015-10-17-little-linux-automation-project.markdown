---
layout: post
title:  "Little linux automation project"
date:   2015-10-17 19:08:34
categories: jekyll update
---

今天发现了个好玩的东西，我在尝试写一个录制鼠标键盘的操作并输出DSL脚本，之后运行来模拟用户操作的程序，windows API 还是有点复杂，所以想先尝试Linux下，


#检测屏幕变化
我发现了 `imagemagick`，之前见过 Ruby 的一个 gem 好像也叫这个名字，
这个软件有命令行接口，比如：

- `import -window root -pause 2 screenshot.jpg`  
可以把整个屏幕在延时两秒之后截图并保存，`-window`也可以指定某个窗口的 id 或 name。

- `compare -metric AE image1 image2 null: 2>&1`  
可以输出两幅图片不同像素点的数目，简单判断两幅图的相似程度。

- `-fuzz 20%`  
这个参数大概是忽略一部分差异

这程序的参数真是奇怪，都是一个横杠`-`，后面还会有`null:`，`x:`什么的。。。

另外用法十分丰富，，文档的目录都有一整屏幕。。。  
贴上 usage 网址：[www.imagemagick.org/Usage](http://www.imagemagick.org/Usage/)

#键鼠操作
Linux下模拟键盘鼠标只需要输出到文件，如`/dev/input/eventX`，可以用命令`cat proc/bus/input/devices`查看具体哪个 event 对应鼠标，哪个对应键盘。

不过我看到了一个命令行工具`xdotool`，已经对鼠标键盘自动化操作封装的很好了：

- `xdotool getmouselocation`获取当前鼠标坐标
- `xdotool click 1`鼠标左键点击
- `xdotool mousemove --sync #{pos[0]} #{pos[1]}`移动鼠标


