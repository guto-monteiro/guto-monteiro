---
layout: page
title: conferences
permalink: /conferences/
description: A growing collection of your cool conferences.
nav: true
nav_order: 3
display_categories: [work, fun]
horizontal: false
---

<!-- pages/conferences.md -->
<div class="conferences">
{% if site.enable_project_categories and page.display_categories %}
  <!-- Display categorized conferences -->
  {% for category in page.display_categories %}
  <a id="{{ category }}" href=".#{{ category }}">
    <h2 class="category">{{ category }}</h2>
  </a>
  {% assign categorized_conferences = site.conferences | where: "category", category %}
  {% assign sorted_conferences = categorized_conferences | sort: "importance" %}
  <!-- Generate cards for each project -->
  {% if page.horizontal %}
  <div class="container">
    <div class="row row-cols-1 row-cols-md-2">
    {% for project in sorted_conferences %}
      {% include conferences_horizontal.liquid %}
    {% endfor %}
    </div>
  </div>
  {% else %}
  <div class="row row-cols-1 row-cols-md-3">
    {% for project in sorted_conferences %}
      {% include conferences.liquid %}
    {% endfor %}
  </div>
  {% endif %}
  {% endfor %}

{% else %}

<!-- Display conferences without categories -->

{% assign sorted_conferences = site.conferences | sort: "importance" %}

  <!-- Generate cards for each project -->

{% if page.horizontal %}

  <div class="container">
    <div class="row row-cols-1 row-cols-md-2">
    {% for project in sorted_conferences %}
      {% include conferences_horizontal.liquid %}
    {% endfor %}
    </div>
  </div>
  {% else %}
  <div class="row row-cols-1 row-cols-md-3">
    {% for project in sorted_conferences %}
      {% include conferences.liquid %}
    {% endfor %}
  </div>
  {% endif %}
{% endif %}
</div>
