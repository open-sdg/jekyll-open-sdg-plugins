require "jekyll"
require_relative "helpers"

# This plugin will be removed before version 1.0.0.
# Do not rely on this!

module Jekyll
  module IndicatorName

    # Takes an indicator ID (dot-delimited or dash-delimited) and returns the
    # translated indicator name (according to the current language). This lookup
    # is as forgiving as possible, to make sure that something is always there.
    #
    # The order of preference in the lookup is:
    #
    # 1. "indicator_name_national" in translated metadata - subfolder approach
    # 2. "indicator_name_national" in translated metadata - translation key approach
    # 3. If the default language, "indicator_name_national" in non-translated metadata
    # 4. If a global indicator, translated global indicator name
    # 5. "indicator_name" in translated metadata - subfolder approach
    # 6. "indicator_name" in translated metadata - translation key approach
    # 7. "indicator_name" in non-translated metadata
    # 8. Finally, fall back to the indicator ID

    def get_indicator_name(inid)

      # Safety code - abort now if id is nil.
      if inid.nil?
        return ""
      end

      # Also make sure it is a string, and otherwise just return it.
      if not inid.is_a? String
        return inid
      end

      # More safety code - abort now if inid is empty.
      if inid.empty?
        return ""
      end

      # Normalize around dash-delimited inids.
      inid = inid.gsub('.', '-')

      # Some variables to help our lookups later.
      page = @context.environments.first['page']
      language = page['language']
      languages = @context.registers[:site].config['languages']
      data = @context.registers[:site].data
      translations = data['translations']
      meta = data['meta'][inid]

      # The metadata fields that we'll seek, first "override" then "default".
      override_field = 'indicator_name_national'
      default_field = 'indicator_name'

      name = false

      # 1. Is there a subfolder translation of the override field?
      if meta and meta.has_key? language
        if !name and meta[language].has_key? override_field
          name = meta[language][override_field]
        end
      end

      # 2. Is the override field actually a "translation key"?
      if !name
        if meta and meta.has_key? override_field
          untranslated = meta[override_field]
          translated = opensdg_translate_key(untranslated, translations, language)
          if untranslated != translated
            # If the opensdg_translate_key() function returned something else,
            # that means it was an actual "translation key".
            name = translated
          end
        end
      end

      # 3. If this is the default language, use the non-translated override
      # field, if available.
      if !name
        if language == languages[0]
          if meta and meta.has_key? override_field
            name = meta[override_field]
          end
        end
      end

      # 4. Is this a global indicator with a translation?
      if !name
        title_key = inid + '-title'
        # For backwards compatibility, look for both dot and dash-delimited keys.
        title_key_dots = inid.gsub('-', '.') + '-title'
        if translations.has_key? language
          if translations[language].has_key? 'global_indicators'
            if translations[language]['global_indicators'].has_key? title_key
              name = translations[language]['global_indicators'][title_key]
            elsif translations[language]['global_indicators'].has_key? title_key_dots
              name = translations[language]['global_indicators'][title_key_dots]
            end
          end
        end
      end

      # 5. Is there a subfolder translation of the default field?
      if !name
        if meta and meta.has_key? language
          if !name and meta[language].has_key? default_field
            name = meta[language][default_field]
          end
        end
      end

      # 6. Is the default field actually a "translation key"?
      if !name
        if meta and meta.has_key? default_field
          untranslated = meta[default_field]
          translated = opensdg_translate_key(untranslated, translations, language)
          if untranslated != translated
            # If the opensdg_translate_key() function returned something else,
            # that means it was an actual "translation key".
            name = translated
          end
        end
      end

      # 7. Use the non-translated default field, if available.
      if !name
        if meta and meta.has_key? default_field
          name = meta[default_field]
        end
      end

      # 8. Still here? Just return the inid.
      if !name
        name = inid
      end

      # Finally return the name with key translation for good measure.
      return opensdg_translate_key(name, translations, language)

    end
  end
end

Liquid::Template.register_filter(Jekyll::IndicatorName)
