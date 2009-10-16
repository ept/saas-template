---
title: Blog Archive
layout: index
---

{% for post in site.posts %}
* [{{ post.title }}](/blog{{ post.url }}) ({{ post.date | date_to_string }})
{% endfor %}
