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

    # This creates variables for use in Liquid templates under "page".
    # We'll create lists of goals, targets, and indicators. These will be put
    # on the page object. Eg: page.sdg_global_goals. To generate these lists
    # we will make use of the metadata. Each item in the list will be a hash
    # containing these keys:
    # - name (translated)
    # - number
    # - sort (for the purposes of sorting the items, since it is not an array)
    # The "available_indicator" hashes also contain all of the metadata for that
    # indicator. The lists are:
    # - sdg_global_goals
    # - sdg_global_targets
    # - sdg_global_indicators
    # - sdg_available_goals
    # - sdg_available_targets
    # - sdg_available_indicators
    # The "global" above means the official UN SDGs. The "available" above means
    # the goals/targets/indicators in use by the country/locality.
    def generate(site)

      # Some general variables needed below.
      translations = site.data['translations']
      default_language = site.config['languages'][0]

      # Hardcoded indicator numbers for all the official UN SDGs.
      global_inids = [
        '1.1.1',
        '1.2.1',
        '1.2.2',
        '1.3.1',
        '1.4.1',
        '1.4.2',
        '1.5.1',
        '1.5.2',
        '1.5.3',
        '1.5.4',
        '1.a.1',
        '1.a.2',
        '1.a.3',
        '1.b.1',
        '10.1.1',
        '10.2.1',
        '10.3.1',
        '10.4.1',
        '10.5.1',
        '10.6.1',
        '10.7.1',
        '10.7.2',
        '10.a.1',
        '10.b.1',
        '10.c.1',
        '11.1.1',
        '11.2.1',
        '11.3.1',
        '11.3.2',
        '11.4.1',
        '11.5.1',
        '11.5.2',
        '11.6.1',
        '11.6.2',
        '11.7.1',
        '11.7.2',
        '11.a.1',
        '11.b.1',
        '11.b.2',
        '11.c.1',
        '12.1.1',
        '12.2.1',
        '12.2.2',
        '12.3.1',
        '12.4.1',
        '12.4.2',
        '12.5.1',
        '12.6.1',
        '12.7.1',
        '12.8.1',
        '12.a.1',
        '12.b.1',
        '12.c.1',
        '13.1.1',
        '13.1.2',
        '13.1.3',
        '13.2.1',
        '13.3.1',
        '13.3.2',
        '13.a.1',
        '13.b.1',
        '14.1.1',
        '14.2.1',
        '14.3.1',
        '14.4.1',
        '14.5.1',
        '14.6.1',
        '14.7.1',
        '14.a.1',
        '14.b.1',
        '14.c.1',
        '15.1.1',
        '15.1.2',
        '15.2.1',
        '15.3.1',
        '15.4.1',
        '15.4.2',
        '15.5.1',
        '15.6.1',
        '15.7.1',
        '15.8.1',
        '15.9.1',
        '15.a.1',
        '15.b.1',
        '15.c.1',
        '16.1.1',
        '16.1.2',
        '16.1.3',
        '16.1.4',
        '16.10.1',
        '16.10.2',
        '16.2.1',
        '16.2.2',
        '16.2.3',
        '16.3.1',
        '16.3.2',
        '16.4.1',
        '16.4.2',
        '16.5.1',
        '16.5.2',
        '16.6.1',
        '16.6.2',
        '16.7.1',
        '16.7.2',
        '16.8.1',
        '16.9.1',
        '16.a.1',
        '16.b.1',
        '17.1.1',
        '17.1.2',
        '17.10.1',
        '17.11.1',
        '17.12.1',
        '17.13.1',
        '17.14.1',
        '17.15.1',
        '17.16.1',
        '17.17.1',
        '17.18.1',
        '17.18.2',
        '17.18.3',
        '17.19.1',
        '17.19.2',
        '17.2.1',
        '17.3.1',
        '17.3.2',
        '17.4.1',
        '17.5.1',
        '17.6.1',
        '17.6.2',
        '17.7.1',
        '17.8.1',
        '17.9.1',
        '2.1.1',
        '2.1.2',
        '2.2.1',
        '2.2.2',
        '2.3.1',
        '2.3.2',
        '2.4.1',
        '2.5.1',
        '2.5.2',
        '2.a.1',
        '2.a.2',
        '2.b.1',
        '2.b.2',
        '2.c.1',
        '3.1.1',
        '3.1.2',
        '3.2.1',
        '3.2.2',
        '3.3.1',
        '3.3.2',
        '3.3.3',
        '3.3.4',
        '3.3.5',
        '3.4.1',
        '3.4.2',
        '3.5.1',
        '3.5.2',
        '3.6.1',
        '3.7.1',
        '3.7.2',
        '3.8.1',
        '3.8.2',
        '3.9.1',
        '3.9.2',
        '3.9.3',
        '3.a.1',
        '3.b.1',
        '3.b.2',
        '3.b.3',
        '3.c.1',
        '3.d.1',
        '4.1.1',
        '4.2.1',
        '4.2.2',
        '4.3.1',
        '4.4.1',
        '4.5.1',
        '4.6.1',
        '4.7.1',
        '4.a.1',
        '4.b.1',
        '4.c.1',
        '5.1.1',
        '5.2.1',
        '5.2.2',
        '5.3.1',
        '5.3.2',
        '5.4.1',
        '5.5.1',
        '5.5.2',
        '5.6.1',
        '5.6.2',
        '5.a.1',
        '5.a.2',
        '5.b.1',
        '5.c.1',
        '6.1.1',
        '6.2.1',
        '6.3.1',
        '6.3.2',
        '6.4.1',
        '6.4.2',
        '6.5.1',
        '6.5.2',
        '6.6.1',
        '6.a.1',
        '6.b.1',
        '7.1.1',
        '7.1.2',
        '7.2.1',
        '7.3.1',
        '7.a.1',
        '7.b.1',
        '8.1.1',
        '8.10.1',
        '8.10.2',
        '8.2.1',
        '8.3.1',
        '8.4.1',
        '8.4.2',
        '8.5.1',
        '8.5.2',
        '8.6.1',
        '8.7.1',
        '8.8.1',
        '8.8.2',
        '8.9.1',
        '8.9.2',
        '8.a.1',
        '8.b.1',
        '9.1.1',
        '9.1.2',
        '9.2.1',
        '9.2.2',
        '9.3.1',
        '9.3.2',
        '9.4.1',
        '9.5.1',
        '9.5.2',
        '9.a.1',
        '9.b.1',
        '9.c.1',
      ]
      global_indicators = {}
      global_targets = {}
      global_goals = {}

      # For available indicators, we simply map the "indictors" collection.
      available_inids = site.collections['indicators'].docs.map do |doc|
        doc.data['indicator']
      end
      available_indicators = {}
      available_targets = {}
      available_goals = {}

      # Set up some empty hashes, per language.
      site.config['languages'].each do |language|
        global_goals[language] = []
        global_targets[language] = []
        global_indicators[language] = []
        available_goals[language] = []
        available_targets[language] = []
        available_indicators[language] = []
      end
      # Throwaway variables to keep track of what has been added.
      already_added_global = []
      already_added_available = []

      # Populate the "global" hashes.
      global_inids.each do |indicator_number|
        goal_number = get_goal_number(indicator_number)
        target_number = get_target_number(indicator_number)
        # To get the name of global stuff, we can use predicable translation
        # keys from the SDG Translations project. Eg: global_goals.1-title
        goal_translation_key = 'global_goals.' + goal_number + '-title'
        target_translation_key = 'global_targets.' + target_number.gsub('.', '-') + '-title'
        indicator_translation_key = 'global_indicators.' + indicator_number.gsub('.', '-') + '-title'
        site.config['languages'].each do |language|
          # Set the goal for this language, once only.
          if already_added_global.index(goal_number) == nil
            already_added_global.push(goal_number)
            global_goals[language].push({
              'number' => goal_number,
              'name' => opensdg_translate_key(goal_translation_key, translations, language),
              'sort' => get_sort_order(goal_number)
            })
          end
          # Set the target for this language, once only.
          if already_added_global.index(target_number) == nil
            already_added_global.push(target_number)
            global_targets[language].push({
              'number' => target_number,
              'name' => opensdg_translate_key(target_translation_key, translations, language),
              'sort' => get_sort_order(target_number)
            })
          end
          # Set the indicator for this language.
          global_indicators[language].push({
            'number' => indicator_number,
            'name' => opensdg_translate_key(indicator_translation_key, translations, language),
            'sort' => get_sort_order(indicator_number)
          })
        end
      end

      # Populate the "available" hashes.
      available_inids.each do |indicator_number|
        goal_number = get_goal_number(indicator_number)
        target_number = get_target_number(indicator_number)
        site.config['languages'].each do |language|
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
          if already_added_available.index(goal_number) == nil
            already_added_available.push(goal_number)
            # For these we just copy the info from the global_goals.
            global_goal = global_goals[language].find {|x| x['number'] == goal_number}
            available_goals[language].push(global_goal)
          end
          # Set the target for this language, once only.
          if already_added_available.index(target_number) == nil
            already_added_available.push(target_number)
            # For these we just copy the info from the global_targets.
            global_target = global_targets[language].find {|x| x['number'] == target_number}
            available_targets[language].push(global_target)
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
            'sort' => get_sort_order(indicator_number),
          }.merge(meta)
          available_indicators[language].push(available_indicator)
        end
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
          doc.data['sdg_global_goals'] = global_goals[language]
          doc.data['sdg_global_targets'] = global_targets[language]
          doc.data['sdg_global_indicators'] = global_indicators[language]
          doc.data['sdg_available_goals'] = available_goals[language]
          doc.data['sdg_available_targets'] = available_targets[language]
          doc.data['sdg_available_indicators'] = available_indicators[language]
          if collection == 'indicators'
            # For indicators we also set the current indicator/target/goal.
            indicator_number = doc.data['indicator']
            goal_number = get_goal_number(indicator_number)
            target_number = get_target_number(indicator_number)
            doc.data['sdg_global_goal'] = global_goals[language].find {|x| x['number'] == goal_number}
            doc.data['sdg_global_target'] = global_targets[language].find {|x| x['number'] == target_number}
            doc.data['sdg_global_indicator'] = global_indicators[language].find {|x| x['number'] == indicator_number}
            doc.data['sdg_available_goal'] = available_goals[language].find {|x| x['number'] == goal_number}
            doc.data['sdg_available_target'] = available_targets[language].find {|x| x['number'] == target_number}
            doc.data['sdg_available_indicator'] = available_indicators[language].find {|x| x['number'] == indicator_number}
          elsif collection == 'goals'
            # For goals we also set the current goal. We rely on the sdg_goal
            # key for the goal number.
            goal_number = doc.data['sdg_goal']
            doc.data['sdg_global_goal'] = global_goals[language].find {|x| x['number'] == goal_number}
            doc.data['sdg_available_goal'] = available_goals[language].find {|x| x['number'] == goal_number}
          end
        end
      end
    end
  end
end
