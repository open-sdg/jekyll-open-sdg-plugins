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
    def get_url(baseurl, language, default_language, number)
      number = number.gsub('.', '-')
      url = baseurl
      if language != default_language
        url += '/' + language
      end
      url + '/' + number
    end

    # Compute a URL for tha goal image, given it's number.
    def get_goal_image(goal_image_base, language, number)
      goal_image_base + '/' + language + '/' + number + '.png'
    end

    # This creates variables for use in Liquid templates under "page".
    # We'll create lists of goals, targets, and indicators. These will be put
    # on the page object. Eg: page.Goals. In order to generate these lists
    # we will make use of the metadata. Each item in the list will be a hash
    # containing these keys:
    # - name (translated)
    # - number (the "id" or number, eg: 1, 1.2, 1.2.1, etc.)
    # - sort (for the purposes of sorting the items, if needed)
    # - global (a Hash containing any equivalent global metadata)
    # The Goal hashes contain additional keys:
    # - short (the translated short version of the name)
    # - icon (path to the translated icon)
    # - url (path to the goal page)
    # The Target hashes contain additional keys:
    # - goal_number (the goal number for this target)
    # The Indicator hashes contain additional keys:
    # - url (path to the indicator page)
    # - goal_number (the goal number for this indicator)
    # - target_number (the target number for this indicator)
    # - [all metadata fields from the indicator]
    # The lists are:
    # - Goals
    # - Targets
    # - Indicators
    # Additionally, on indicator pages themselves, there are variables for
    # the current goal/target/indicator:
    # - Goal
    # - Target
    # - Indicator
    # Similarly, on goal pages themselves, there are variables for the current
    # goal:
    # - Goal
    def generate(site)

      # Some general variables needed below.
      translations = site.data['translations']
      default_language = site.config['languages'][0]
      baseurl = site.config['baseurl']
      if baseurl == ''
        baseurl = '/'
      end
      goal_image_base = site.config['goal_image_base']

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
      site.config['languages'].each do |language|
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

        site.config['languages'].each do |language|
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
          if site.config['translated_builds']
            meta = site.data[language]['meta'][meta_key]
          else
            meta = site.data['meta'][meta_key]
          end

          # Set the goal for this language, once only.
          if already_added[language].index(goal_number) == nil
            already_added[language].push(goal_number)
            available_goals[language].push({
              'number' => goal_number,
              'name' => opensdg_translate_key(goal_translation_key + '-title', translations, language),
              'short' => opensdg_translate_key(goal_translation_key + '-short', translations, language),
              'url' => get_url(baseurl, language, default_language, goal_number),
              'icon' => get_goal_image(goal_image_base, language, goal_number),
              'sort' => get_sort_order(goal_number),
              'global' => global_goal,
            })
          end
          # Set the target for this language, once only.
          if already_added[language].index(target_number) == nil
            already_added[language].push(target_number)
            available_targets[language].push({
              'number' => target_number,
              'name' => opensdg_translate_key(target_translation_key + '-title', translations, language),
              'sort' => get_sort_order(target_number),
              'goal_number' => goal_number,
              'global' => global_target,
            })
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
            'name' => opensdg_translate_key(indicator_name, translations, language),
            'url' => get_url(baseurl, language, default_language, indicator_number),
            'sort' => get_sort_order(indicator_number),
            'goal_number' => goal_number,
            'target_number' => target_number,
            'global' => global_indicator,
          }
          # Translate and add any metadata.
          meta.each do |key, value|
            available_indicator[key] = opensdg_translate_key(value, translations, language)
          end
          available_indicators[language].push(available_indicator)
        end
      end

      # Sort all the items.
      site.config['languages'].each do |lang|
        available_goals[lang] = available_goals[lang].sort_by { |x| x['sort'] }
        available_targets[lang] = available_targets[lang].sort_by { |x| x['sort'] }
        available_indicators[lang] = available_indicators[lang].sort_by { |x| x['sort'] }
      end

      # Next set the stuff on each doc in certain collections, according
      # to the doc's language. We'll be putting the global stuff on every
      # page, goal, and indicator across the site. This may be a bit memory-
      # intensive during the Jekyll build, but it is nice to have it available
      # for consistency.
      collections = ['pages', 'goals', 'indicators']
      collections.each do |collection|
        site.collections[collection].docs.each do |doc|
          # Ensure it has a language.
          if !doc.data.has_key? 'language'
            doc.data['language'] = default_language
          end
          language = doc.data['language']
          # Set these on the page object, capitalized to avoid collisions.
          doc.data['Goals'] = available_goals[language]
          doc.data['Targets'] = available_targets[language]
          doc.data['Indicators'] = available_indicators[language]
          if collection == 'indicators'
            # For indicators we also set the current indicator/target/goal.
            indicator_number = doc.data['indicator']
            goal_number = get_goal_number(indicator_number)
            target_number = get_target_number(indicator_number)
            doc.data['Goal'] = available_goals[language].find {|x| x['number'] == goal_number}
            doc.data['Target'] = available_targets[language].find {|x| x['number'] == target_number}
            doc.data['Indicator'] = available_indicators[language].find {|x| x['number'] == indicator_number}
          elsif collection == 'goals'
            # For goals we also set the current goal. We rely on the sdg_goal
            # key for the goal number.
            goal_number = doc.data['sdg_goal']
            doc.data['Goal'] = available_goals[language].find {|x| x['number'] == goal_number}
          end
        end
      end
    end
  end
end
