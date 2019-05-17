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
