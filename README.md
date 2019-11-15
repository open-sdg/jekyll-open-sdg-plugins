# jekyll-open-sdg-plugins

> 💎 Jekyll plugins for use with the Open SDG platform

This plugin provides some Jekyll functionality for the [Open SDG](https://github.com/open-sdg/open-sdg) platform.

The functionality provided consists of:

## 1. A "t" Liquid filter for translating strings.

Usage example:

```
{{ my_variable | t }}
```

## 2. Fill in missing fields to allow partially translated metadata.

This allows metadata to be translated, field-by-field as needed, in subfolders in the data repository.

## 3. Automatically create goal pages based on data.

This creates goal pages automatically based on the data, so that the site repository does not need to maintain a `_goals` folder. It depends on a `_config.yml` setting.

Usage example (in `_config.yml`):
```
create_goals:
  # This determines which layout is used to render the pages.
  layout: goal
```

## 4. Automatically create indicator pages based on data.

This creates indicator pages automatically based on the data, so that the site repository does not need to maintain a `_indicators` folder. It depends on a `_config.yml` setting.

Usage example (in `_config.yml`):
```
create_indicators:
  # This determines which layout is used to render the pages.
  layout: indicator
```

## 5. Automatically create 4 required pages.

This automates the creation of 4 required pages that all implementations of Open SDG will need. These consist of:

* the home page: /
* the indicators json page: /indicators.json
* the search results page: /search
* the reporting status page: /reporting-status

There are advanced options for overriding the location of these pages (see creae_pages.rb). But see the example below to use the defaults.

Usage example (in `_config.yml`):
```
create_pages: true
```

## 6. Automatically fetch remote data and translations.

This automates the fetching of the remote data (from the "data repository") and any remote translations.

Note: This feature is disabled if "jekyll_get_json" is in the site config. This was the older (more verbose) way to do this.

Usage example (in `_config.yml`):
```
remote_data_prefix: https://mygithuborg.github.io/my-data-repository
remote_translations:
  - https://open-sdg.github.io/sdg-translations/translations-0.6.0.json

```

For those interested in switching to this convenience feature, note that this makes the "jekyll_get_json" and "remotedatabaseurl" settings obsolete; so they can be removed.

## 7. Provide standard variables on all pages, for use in templates

This feature provides access to Hashes for goals, targets, and indicators. Each
contains the following keys:
* number (eg, "1" for a goal, "1.1" for a target, "1.1.1" for an indicator)
* slug (eg, "1" for a goal, "1-1", for a target, "1-1-1" for an indicator)
* name (the fully-translated name of the goal/target/indicator
* sort (a string suitable for use in sorting the goals/targets/indicators)
* global (an equivalent Hash containing specifically "global" versions)

Additionally, indicators contain:
* url (the URL of that indicator's page)
* goal_number (the number of that indicator's goal)
* target_number (the number of that indicator's target)
* [all the indicator's metadata fields]

Additionally, targets contain:
* goal_number (the number of that target's goal)

Additionally, goals contain:
* url (the URL of that goal's page)
* icon (the URL of that goal's icon)
* short (the short version of the goal name, translated)

The following variables can be used on ALL pages:

* goals : Array of goals
* targets : Array of targets
* indicators : Array of indicators
* baseurl: A page-specific version of site.baseurl, taking language into account
* language: The language code for the current page
* language_public: The "public" language code, which may be different from the
  language code.
* t: A hash of all the compiled translations in the current language

The following variables can be used on all indicator pages:

* goal : the current goal
* target : the current target
* indicator : the current indicator

The following variables can be used on all goal pages:

* goal : the current goal

Examples of usage:

Printing titles for all available indicators in Goal 2:
```
{% assign indicators = page.indicators | where: "goal_number", "2" %}
{% for indicator in indicators %}
  {{ indicator.name }}
{% endfor %}
```

Printing the short name for the current goal, on a goal page:
```
{{ page.goal.short }}
```

Printing the name of all targets in a particular, on that goal page:
```
{% assign targets = page.targets | where: "goal_number", page.goal.number %}
{% for target in targets %}
  {{ target.name }}
{% endfor %}

## 8. Lookup goals/targets/indicators by ID

The hashes detailed above in #7 can also be looked up by id, with the `sdg_lookup` filter.

Examples of usage:

Looking up target 7.1 and printing its name

```
{% assign target = '7.1' | sdg_lookup %}
{{ target.name }}
```