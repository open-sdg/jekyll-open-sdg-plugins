require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class SDGVariables < Jekyll::Generator
    safe true
    priority :low

    # Get a goal number from an indicator number.
    def get_goal_number(indicator_number)
      parts = indicator_number.split('.')
      parts[0]
    end

    # Get a target number from an indicator number.
    def get_target_number(indicator_number)
      parts = indicator_number.split('.')
      if parts.length() < 2
        indicator_number
      else
        parts[0] + '.' + parts[1]
      end
    end

    # Is this string numeric?
    def is_number? string
      true if Float(string) rescue false
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
          if is_number?(part)
            part = '0' + part
          else
            part = part + part
          end
        end
        sort_order += part
      end
      sort_order
    end

    # Get previous item from an array, or loop to the end.
    def get_previous_item(list, index)
      decremented = index - 1
      if decremented < 0
        decremented = list.length() - 1
      end
      list[decremented]
    end

    # Get next item from an array, or loop to the beginning.
    def get_next_item(list, index)
      incremented = index + 1
      if incremented >= list.length()
        incremented = 0
      end
      list[incremented]
    end

    # Wrapper of get_previous_item specifically for indicators.
    def get_previous_indicator(list, index)
      indicator = get_previous_item(list, index)
      # Skip placeholder indicators.
      is_placeholder = (indicator.has_key?('placeholder') and indicator['placeholder'] != '')
      while (is_placeholder)
        index -= 1
        if index < 0
          index = list.length() - 1
        end
        indicator = get_previous_item(list, index)
        is_placeholder = (indicator.has_key?('placeholder') and indicator['placeholder'] != '')
      end
      return indicator
    end

    # Wrapper of get_next_item specifically for indicators.
    def get_next_indicator(list, index)
      indicator = get_next_item(list, index)
      # Skip placeholder indicators.
      is_placeholder = (indicator.has_key?('placeholder') and indicator['placeholder'] != '')
      while (is_placeholder)
        index += 1
        if index >= list.length()
          index = 0
        end
        indicator = get_next_item(list, index)
        is_placeholder = (indicator.has_key?('placeholder') and indicator['placeholder'] != '')
      end
      return indicator
    end

    # The Jekyll baseurl is user-configured, and can be inconsistent. This
    # ensure it is consistent in whether it starts/ends with a slash.
    def normalize_baseurl(baseurl)
      if baseurl == '' || baseurl.nil?
        baseurl = '/'
      end
      if !baseurl.start_with? '/'
        baseurl = '/' + baseurl
      end
      if !baseurl.end_with? '/'
        baseurl = baseurl + '/'
      end
      baseurl
    end

    # Compute a URL for an item, given it's number.
    def get_url(baseurl, language, number, languages, languages_public)

      baseurl = normalize_baseurl(baseurl)

      default_language = languages[0]
      language_public = language
      if languages_public && languages_public[language]
        language_public = languages_public[language]
      end
      if default_language != language
        baseurl += language_public + '/'
      end

      number = number.gsub('.', '-')
      baseurl + number
    end

    # Get a Hash of all the URLs based on one particular one.
    def get_all_urls(url, language, languages, languages_public, baseurl)

      baseurl = normalize_baseurl(baseurl)

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
        default_language_url = baseurl + url_without_language
        # Fix potential double-slash.
        default_language_url = default_language_url.gsub('//', '/')
        urls[default_language] = default_language_url
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
        urls[other_language] = baseurl + other_language_public + url_without_language
      end
      urls
    end

    # Compute a URL for tha goal image, given it's number.
    def get_goal_image(goal_image_base, language, number, extension)
      goal_image_base + '/' + language + '/' + number + '.' + extension
    end

    # Calculate the correct content for the indicator tabs.
    def set_indicator_tab_content(indicator_config, site_config)
      defaults = {
        'tab_1' => 'chart',
        'tab_2' => 'table',
        'tab_3' => 'map',
        'tab_4' => 'embed',
      }
      # Use the site config or defaults if necessary.
      tabs = site_config.has_key?('indicator_tabs') ? site_config['indicator_tabs'] : defaults
      # Override for this indicator if needed.
      if indicator_config.has_key?('indicator_tabs')
        if indicator_config['indicator_tabs'].has_key?('override')
          if indicator_config['indicator_tabs']['override']
            tabs = indicator_config['indicator_tabs']
          end
        end
      end

      embed_has_label = (indicator_config.has_key?('embedded_feature_tab_title') && indicator_config['embedded_feature_tab_title'] != '')
      embed_label = embed_has_label ? indicator_config['embedded_feature_tab_title'] : 'Embed'

      labels = {
        'chart' => 'indicator.chart',
        'table' => 'indicator.table',
        'map' => 'indicator.map',
        'embed' => embed_label,
      }

      tabs_list = []
      ['tab_1', 'tab_2', 'tab_3', 'tab_4'].each do |tab_number|
        type = tabs[tab_number]
        if type == 'hide'
          next
        end

        if type == 'embed'
          embed_url = (indicator_config.has_key?('embedded_feature_url') && indicator_config['embedded_feature_url'] != '')
          embed_html = (indicator_config.has_key?('embedded_feature_html') && indicator_config['embedded_feature_html'] != '')
          unless embed_url || embed_html
            next
          end
        elsif type == 'map'
          if indicator_config['slug'] == '1-3-1'
            puts indicator_config
          end
          show_map = (indicator_config.has_key?('data_show_map') && indicator_config['data_show_map'])
          unless show_map
            next
          end
        end

        tabs_list.push({
          'type' => type,
          'label' => labels[type],
        })
      end

      indicator_config['indicator_tabs_list'] = tabs_list
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
      languages_public = opensdg_languages_public(site)
      default_language = languages[0]
      baseurl = site.config['baseurl']
      goal_image_base = 'https://open-sdg.org/sdg-translations/assets/img/goals'
      if site.config.has_key? 'goal_image_base'
        goal_image_base = site.config['goal_image_base']
      end
      goal_image_extension = 'png'
      if site.config.has_key?('goal_image_extension') && site.config['goal_image_extension'] != ''
        goal_image_extension = site.config['goal_image_extension']
      end

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
            # Also for untranslated builds, we need to support the "subfolder"
            # approach for metadata translation. (This is handled at build-time
            # for translated builds.)
            if meta.has_key? language
              meta = meta.merge(meta[language])
              meta.delete(language)
            end
          end

          is_standalone = (meta.has_key?('standalone') and meta['standalone'])
          is_placeholder = (meta.has_key?('placeholder') and meta['placeholder'] != '')

          # Set the goal for this language, once only.
          if !is_standalone && already_added[language].index(goal_number) == nil
            already_added[language].push(goal_number)
            available_goal = {
              'number' => goal_number,
              'slug' => goal_number.gsub('.', '-'),
              'name' => opensdg_translate_key(goal_translation_key + '-title', translations, language),
              'short' => opensdg_translate_key(goal_translation_key + '-short', translations, language),
              'url' => get_url(baseurl, language, goal_number, languages, languages_public),
              'icon' => get_goal_image(goal_image_base, language, goal_number, goal_image_extension),
              'sort' => get_sort_order(goal_number),
              'global' => global_goal,
            }
            available_goals[language].push(available_goal)
          end
          # Set the target for this language, once only.
          if !is_standalone && already_added[language].index(target_number) == nil
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
          indicator_path = indicator_number
          if is_standalone && meta.has_key?('permalink') && meta['permalink'] != ''
            indicator_path = meta['permalink']
          end
          indicator_sort = get_sort_order(indicator_number)
          if meta.has_key?('sort') && meta['sort'] != ''
            # Allow metadata 'sort' field to override the default sort.
            indicator_sort = meta['sort']
          end
          if meta.has_key?('graph_annotations') && meta['graph_annotations'].length > 0
            meta['graph_annotations'].each do |annotation|
              if annotation.has_key?('borderDash') && annotation['borderDash'].is_a?(String)
                annotation['borderDash'] = [2, 2]
                opensdg_notice('The "borderDash" property in graph annotations must be an array. Using [2, 2].')
              end
            end
          end
          available_indicator = {
            'number' => indicator_number,
            'slug' => indicator_number.gsub('.', '-'),
            'name' => opensdg_translate_key(indicator_name, translations, language),
            'url' => get_url(baseurl, language, indicator_path, languages, languages_public),
            'sort' => indicator_sort,
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
          # Ensure it has a valid language.
          if !languages.include? doc.data['language']
            message = "NOTICE: The document '#{doc.basename}' has an unexpected language '#{doc.data['language']}' so we are using the default language '#{default_language}' instead."
            opensdg_notice(message)
            doc.data['language'] = default_language
          end
          language = doc.data['language']
          # Set these on the page object.
          doc.data['goals'] = available_goals[language]
          doc.data['targets'] = available_targets[language]
          doc.data['indicators'] = available_indicators[language]
          doc.data['baseurl'] = get_url(baseurl, language, '', languages, languages_public)
          doc.data['url_by_language'] = get_all_urls(doc.url, language, languages, languages_public, baseurl)
          doc.data['t'] = site.data['translations'][language]

          # Set the remote_data_prefix for this page.
          if site.config.has_key?('remote_data_prefix') && opensdg_is_path_remote(site.config['remote_data_prefix'])
            doc.data['remote_data_prefix'] = site.config['remote_data_prefix']
          else
            doc.data['remote_data_prefix'] = normalize_baseurl(baseurl)
          end
          if opensdg_translated_builds(site)
            doc.data['remote_data_prefix_untranslated'] = File.join(doc.data['remote_data_prefix'], 'untranslated')
            doc.data['remote_data_prefix'] = File.join(doc.data['remote_data_prefix'], language)
          else
            doc.data['remote_data_prefix_untranslated'] = doc.data['remote_data_prefix']
          end

          # Set the logo for this page.
          logo = {}
          match = false
          if site.config.has_key?('logos') && site.config['logos'].length > 0
            match = site.config['logos'].find{ |item| item['language'] == language }
            unless match
              match = site.config['logos'].find{ |item| item.fetch('language', '') == '' }
            end
          end
          if match
            src = match['src']
            unless src.start_with?('http')
              src = normalize_baseurl(baseurl) + src
            end
            logo['src'] = src
            logo['alt'] = opensdg_translate_key(match['alt'], translations, language)
          else
            logo['src'] = normalize_baseurl(baseurl) + 'assets/img/SDG_logo.png'
            alt_text = opensdg_translate_key('general.sdg', translations, language)
            alt_text += ' - '
            alt_text += opensdg_translate_key('header.tag_line', translations, language)
            logo['alt'] = alt_text
          end
          doc.data['logo'] = logo

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
            indicator_index = available_indicators[language].find_index {|x| x['number'] == indicator_number}
            doc.data['indicator'] = available_indicators[language][indicator_index]
            doc.data['next'] = get_next_indicator(available_indicators[language], indicator_index)
            doc.data['previous'] = get_previous_indicator(available_indicators[language], indicator_index)

            # Also calculate the content for the indicator tabs.
            set_indicator_tab_content(doc.data, site.config)

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
            goal_index = available_goals[language].find_index {|x| x['number'] == goal_number}
            doc.data['goal'] = available_goals[language][goal_index]
            doc.data['next'] = get_next_item(available_goals[language], goal_index)
            doc.data['previous'] = get_previous_item(available_goals[language], goal_index)
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
