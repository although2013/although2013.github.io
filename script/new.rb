
title = ARGV[0]

t = Time.now

name_1 = t.to_s[0..9]
name_2 = title.split.map { |w| "-#{w}" }.join





data = <<-head
---
layout: post
title:  \"#{title.capitalize}\"
date:   #{t.to_s[0..18]}
categories: jekyll update
---
head



File.open("_posts/#{name_1}#{name_2}".markdown, "w") { |file| file.puts data }