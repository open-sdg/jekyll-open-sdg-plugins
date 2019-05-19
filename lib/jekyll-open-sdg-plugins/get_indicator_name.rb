require "jekyll"
require_relative "helpers"

module Jekyll
  module IndicatorName

    # Takes an indicator ID (dot-delimited or dash-delimited) and returns the
    # translated indicator name (according to the current language). This lookup
    # is as forgiving as possible, to make sure that something is always there.
    #
    # The order of preference in the lookup is:
    #
    # 1. "indicator_name" in translated metadata
    # 2. "title" in translated metadata
    # 3. if global, translated global indicator name
    # 4. "indicator_name" in non-translated metadata
    # 5. "title" in non-translated metadata
    # 6. indicator ID
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
      data = @context.registers[:site].data
      translations = data['translations']
      meta = data['meta'][inid]
      metadata_fields = ['indicator_name', 'title']

      name = false

      # First choice, is there a subfolder translation of any metadata fields?
      if meta and meta.has_key? language
        metadata_fields.each do |field|
          if !name and meta[language].has_key? field
            name = meta[language][field]
          end
        end
      end

      # Next choice, are any of the metadata fields a translation key?
      if !name
        metadata_fields.each do |field|
          if !name and meta and meta.has_key? field
            untranslated = meta[field]
            translated = opensdg_translate_key(untranslated, translations, language)
            if untranslated != translated
              # If the opensdg_translate_key() function returned something else,
              # that means it was an actual translation key.
              name = translated
            end
          end
        end
      end

      # Next, is this a global indicator with a translation? For this we actually
      # need the inid dot-delimited.
      if !name
        inid_dots = inid.gsub('-', '.')
        if translations.has_key? language
          if translations[language].has_key? 'global_indicators'
            if translations[language]['global_indicators'].has_key? inid_dots
              name = translations[language]['global_indicators'][inid_dots]['title']
            end
          end
        end
      end

      # Next just return any untranslated metadata field.
      if !name
        metadata_fields.each do |field|
          if !name and meta and meta.has_key? field
            name = meta[field]
          end
        end
      end

      # Still here? Just return the inid.
      if !name
        name = inid
      end

      # Finally return the name with key translation for good measure.
      return opensdg_translate_key(name, translations, language)

    end
  end
end

Liquid::Template.register_filter(Jekyll::IndicatorName)
