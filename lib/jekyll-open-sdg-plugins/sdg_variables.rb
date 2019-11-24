require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class SDGVariables < Jekyll::Generator
    safe true
    priority :lowest

    # Get a goal number from an indicator number.
    def get_goal_number(indicator_number)
      parts = indicator_number.split('.')
      parts[0]
    end

    # Get a target number from an indicator number.
    def get_target_number(indicator_number)
      parts = indicator_number.split('.')
      parts[0] + '.' + parts[1]
    end

    # Make any goal/target/indicator number suitable for use in sorting.
    def get_sort_order(number)
      if number.is_a? Numeric
        number = number.to_s
      end
      sort_order = ''
      parts = number.split('.')
      parts.each do |part|
        if part.length == 1
          part = '0' + part
        end
        sort_order += part
      end
      sort_order
    end

    # Compute a URL for an item, given it's number.
    def get_url(baseurl, language, number, languages, languages_public)

      default_language = languages[0]
      language_public = language
      if languages_public && languages_public[language]
        language_public = languages_public[language]
      end
      if baseurl == ''
        baseurl = '/'
      end
      if default_language != language
        baseurl += language_public + '/'
      end
      if !baseurl.start_with? '/'
        baseurl = '/' + baseurl
      end
      if !baseurl.end_with? '/'
        baseurl = baseurl + '/'
      end

      number = number.gsub('.', '-')
      baseurl + number
    end

    # Get a Hash of all the URLs based on one particular one.
    def get_all_urls(url, language, languages, languages_public)
      language_public = language
      if languages_public && languages_public[language]
        language_public = languages_public[language]
      end

      # First figure out the language-free URL.
      default_language = languages[0]
      if language == default_language
        url_without_language = url
      else
        url_without_language = url.gsub('/' + language_public + '/', '/')
      end

      urls = {
        language => url
      }
      if language != default_language
        urls[default_language] = url_without_language
      end
      languages.each do |other_language|
        if other_language == language
          next
        end
        if other_language == default_language
          next
        end
        other_language_public = other_language
        if languages_public && languages_public[other_language]
          other_language_public = languages_public[other_language]
        end
        urls[other_language] = '/' + other_language_public + url_without_language
      end
      urls
    end

    # Compute a URL for tha goal image, given it's number.
    def get_goal_image(goal_image_base, language, number)
      goal_image_base + '/' + language + '/' + number + '.png'
    end

    # This creates variables for use in Liquid templates under "page".
    # We'll create lists of goals, targets, and indicators. These will be put
    # on the page object. Eg: page.goals. In order to generate these lists
    # we will make use of the metadata. Each item in the list will be a hash
    # containing these keys:
    # - name (translated)
    # - number (the "id" or number, eg: 1, 1.2, 1.2.1, etc.)
    # - slug (version of 'number' but with dashes instead of dots)
    # - sort (for the purposes of sorting the items, if needed)
    # - global (a Hash containing any equivalent global metadata)
    # The goal hashes contain additional keys:
    # - short (the translated short version of the name)
    # - icon (path to the translated icon)
    # - url (path to the goal page)
    # The target hashes contain additional keys:
    # - goal_number (the goal number for this target)
    # The indicator hashes contain additional keys:
    # - url (path to the indicator page)
    # - goal_number (the goal number for this indicator)
    # - target_number (the target number for this indicator)
    # - [all metadata fields from the indicator]
    # The lists are:
    # - goals
    # - targets
    # - indicators
    # Additionally, on indicator pages themselves, there are variables for
    # the current goal/target/indicator:
    # - goal
    # - target
    # - indicator
    # Similarly, on goal pages themselves, there are variables for the current
    # goal:
    # - goal
    def generate(site)

      # Some general variables needed below.
      translations = site.data['translations']
      languages = site.config['languages']
      languages_public = site.config['languages_public']
      default_language = languages[0]
      baseurl = site.config['baseurl']
      goal_image_base = site.config['goal_image_base']

      # These keys are flagged as "protected" here so that we can make sure that
      # country-specific metadata doesn't use any of these fields.
      protected_keys = ['goals', 'goal', 'targets', 'target', 'indicators',
        'indicator', 'language', 'name', 'number', 'sort', 'global', 'url',
        'goal_number', 'target_number'
      ]

      # Figure out from our translations the global indicator numbers.
      global_inids = translations[default_language]['global_indicators'].keys
      global_inids = global_inids.select { |x| x.end_with? '-title' }
      global_inids = global_inids.map { |x| x.gsub('-title', '').gsub('-', '.') }

      # For available indicators, we simply map the "indicators" collection.
      available_inids = site.collections['indicators'].docs.select { |x| x.data['language'] == default_language }
      available_inids = available_inids.map { |x| x.data['indicator'] }
      available_indicators = {}
      available_targets = {}
      available_goals = {}

      # Some throwaway variables to keep track of what has been added.
      already_added = {}

      # Set up some empty hashes, per language.
      languages.each do |language|
        available_goals[language] = []
        available_targets[language] = []
        available_indicators[language] = []
        already_added[language] = []
      end

      # Populate the hashes.
      available_inids.each do |indicator_number|
        goal_number = get_goal_number(indicator_number)
        target_number = get_target_number(indicator_number)
        is_global_indicator = global_inids.index(indicator_number) != nil
        # To get the name of global stuff, we can use predicable translation
        # keys from the SDG Translations project. Eg: global_goals.1-title
        goal_translation_key = 'global_goals.' + goal_number
        target_translation_key = 'global_targets.' + target_number.gsub('.', '-')
        indicator_translation_key = 'global_indicators.' + indicator_number.gsub('.', '-')

        languages.each do |language|
          global_goal = {
            'name' => opensdg_translate_key(goal_translation_key + '-title', translations, language),
            # TODO: More global metadata about goals?
          }
          global_target = {
            'name' => opensdg_translate_key(target_translation_key + '-title', translations, language),
            # TODO: More global metadata about targets?
          }
          global_indicator = {}
          if is_global_indicator
            global_indicator = {
              'name' => opensdg_translate_key(indicator_translation_key + '-title', translations, language),
              # TODO: More global metadata about indicators?
            }
          end

          # We have to get the metadata for the indicator/language.
          meta = {}
          # Currently the meta keys are dash-delimited. This is a little
          # arbitrary (it's because they came from filenames) and could maybe
          # be changed eventually to dot-delimited for consistency.
          meta_key = indicator_number.gsub('.', '-')
          # The location of the metadata is different depending on whether we are
          # using "translated_builds" or not.
          if opensdg_translated_builds(site)
            meta = site.data[language]['meta'][meta_key]
          else
            meta = site.data['meta'][meta_key]
          end

          # Set the goal for this language, once only.
          if already_added[language].index(goal_number) == nil
            already_added[language].push(goal_number)
            available_goal = {
              'number' => goal_number,
              'slug' => goal_number.gsub('.', '-'),
              'name' => opensdg_translate_key(goal_translation_key + '-title', translations, language),
              'short' => opensdg_translate_key(goal_translation_key + '-short', translations, language),
              'url' => get_url(baseurl, language, goal_number, languages, languages_public),
              'icon' => get_goal_image(goal_image_base, language, goal_number),
              'sort' => get_sort_order(goal_number),
              'global' => global_goal,
            }
            available_goals[language].push(available_goal)
          end
          # Set the target for this language, once only.
          if already_added[language].index(target_number) == nil
            already_added[language].push(target_number)
            available_target = {
              'number' => target_number,
              'slug' => target_number.gsub('.', '-'),
              'name' => opensdg_translate_key(target_translation_key + '-title', translations, language),
              'sort' => get_sort_order(target_number),
              'goal_number' => goal_number,
              'global' => global_target,
            }
            available_targets[language].push(available_target)
          end
          # Set the indicator for this language. Unfortunately we are currently
          # using two possible fields for the indicator name:
          # - indicator_name
          # - indicator_name_national
          # TODO: Eventually standardize around 'indicator_name' and drop support
          # for 'indicator_name_national'.
          indicator_name = ''
          if meta.has_key? 'indicator_name_national'
            indicator_name = meta['indicator_name_national']
          else
            indicator_name = meta['indicator_name']
          end
          available_indicator = {
            'number' => indicator_number,
            'slug' => indicator_number.gsub('.', '-'),
            'name' => opensdg_translate_key(indicator_name, translations, language),
            'url' => get_url(baseurl, language, indicator_number, languages, languages_public),
            'sort' => get_sort_order(indicator_number),
            'goal_number' => goal_number,
            'target_number' => target_number,
            'global' => global_indicator,
          }
          # Translate and add any metadata.
          meta.each do |key, value|
            if !protected_keys.include? key
              available_indicator[key] = opensdg_translate_key(value, translations, language)
            end
          end
          available_indicators[language].push(available_indicator)
        end
      end

      # Sort all the items.
      languages.each do |lang|
        available_goals[lang] = available_goals[lang].sort_by { |x| x['sort'] }
        available_targets[lang] = available_targets[lang].sort_by { |x| x['sort'] }
        available_indicators[lang] = available_indicators[lang].sort_by { |x| x['sort'] }
      end

      # Next set the stuff on each doc in certain collections, according
      # to the doc's language. We'll be putting the global stuff on every
      # page, goal, and indicator across the site. This may be a bit memory-
      # intensive during the Jekyll build, but it is nice to have it available
      # for consistency.
      site.collections.keys.each do |collection|
        site.collections[collection].docs.each do |doc|
          # Ensure it has a language.
          if !doc.data.has_key? 'language'
            doc.data['language'] = default_language
          end
          language = doc.data['language']
          # Set these on the page object.
          doc.data['goals'] = available_goals[language]
          doc.data['targets'] = available_targets[language]
          doc.data['indicators'] = available_indicators[language]
          doc.data['baseurl'] = get_url(baseurl, language, '', languages, languages_public)
          doc.data['url_by_language'] = get_all_urls(doc.url, language, languages, languages_public)
          doc.data['t'] = site.data['translations'][language]

          if collection == 'indicators'
            # For indicators we also set the current indicator/target/goal.
            if doc.data.has_key? 'indicator_number'
              indicator_number = doc.data['indicator_number']
            elsif doc.data.has_key? 'indicator'
              # Backwards compatibility.
              indicator_number = doc.data['indicator']
            else
              raise "Error: An indicator does not have 'indicator_number' property."
            end
            # Force the indicator number to be a string.
            if indicator_number.is_a? Numeric
              indicator_number = indicator_number.to_s
            end
            goal_number = get_goal_number(indicator_number)
            target_number = get_target_number(indicator_number)
            doc.data['goal'] = available_goals[language].find {|x| x['number'] == goal_number}
            doc.data['target'] = available_targets[language].find {|x| x['number'] == target_number}
            doc.data['indicator'] = available_indicators[language].find {|x| x['number'] == indicator_number}
          elsif collection == 'goals'
            # For goals we also set the current goal.
            if doc.data.has_key? 'goal_number'
              goal_number = doc.data['goal_number']
            elsif doc.data.has_key? 'sdg_goal'
              # Backwards compatibility.
              goal_number = doc.data['sdg_goal']
            else
              raise "Error: A goal does not have 'goal_number' property."
            end
            # Force the goal number to be a string.
            if goal_number.is_a? Numeric
              goal_number = goal_number.to_s
            end
            doc.data['goal'] = available_goals[language].find {|x| x['number'] == goal_number}
          end
        end
      end

      # Finally let's set all these on the site object so that they can be
      # easily looked up later.
      lookup = {}
      available_goals.each do |language, items|
        lookup[language] = {}
        items.each do |item|
          number = item['number']
          lookup[language][number] = item
        end
      end
      available_targets.each do |language, items|
        items.each do |item|
          number = item['number']
          lookup[language][number] = item
        end
      end
      available_indicators.each do |language, items|
        items.each do |item|
          number = item['number']
          lookup[language][number] = item
        end
      end
      site.data['sdg_lookup'] = lookup
    end
  end
end

module Jekyll
  module SDGLookup
    # This provides a "sdg_lookup" filter that takes an id and returns a hash
    # representation of a goal, target, or indicator.
    def sdg_lookup(number)
      number = number.gsub('-', '.')
      data = @context.registers[:site].data
      page = @context.environments.first['page']
      language = page['language']
      return data['sdg_lookup'][language][number]
    end
  end
end

Liquid::Template.register_filter(Jekyll::SDGLookup)
