require "jekyll"
require_relative "helpers"

module Jekyll
  module TranslateDate

    # Takes a raw Jekyll date and returns a translated string according to the
    # language of the current page and a date format given.
    def t_date(date, format_type)

      original = date

      # Determine the language of the current page.
      config = @context.registers[:site].config
      translations = @context.registers[:site].data['translations']
      language = @context.environments.first['page']['language']

      # Try to find the specified date format in the site config. It needs to be
      # something like this, assuming the "format_type" param is "standard":
      #
      # date_formats:
      #   - type: standard
      #     language: en
      #     format: "%b %d, %Y"
      #   - type: standard
      #     language: es
      #     format: "%d de %b de %Y"
      #
      date_format = '%b %d, %Y'
      if config.has_key?('date_formats')
        
        # Abort if this setting is using an old format.
        if config['date_formats'].is_a?(Hash)
          opensdg_error('The "date_formats" site configuration must be in a list format. See the documentation here: https://open-sdg.readthedocs.io/en/latest/configuration/#date_formats')
        end

        # In the current form of data_formats, it is an array of hashes, each
        # containing "type", "language", and "format" keys.
        if config['date_formats'].is_a?(Array)
          date_format_config = config['date_formats'].find {|d| d['type'] == format_type && d['language'] == language }
          if date_format_config
            date_format = date_format_config['format']
          end
        end

      end

      # Support timestamps.
      if date.is_a? Integer
        # Convert milliseconds to seconds if necessary.
        if date > 9000000000
          date = date / 1000
        end
        begin
          date = Time.at(date).utc
        rescue => err
          return original
        end
      end

      # Support other strings.
      if date.is_a? String
        begin
          date = Time.parse(date).utc
        rescue => err
          return original
        end
      end

      # Avoid nil errors.
      unless date.is_a? Time
        return original
      end

      # Convert the date into English.
      english = date.strftime(date_format)

      # Now "tokenize" that date by spaces.
      parts = english.split(' ')

      translated_parts = []
      parts.each do |part|
        # Special case: see if we need to remove a comma from the end.
        removed_comma = false
        if part.end_with? ','
          part = part.delete_suffix(',')
          removed_comma = true
        end
        # Look for a translation in the "calendar" translation group.
        key = 'calendar.' + part
        translated_part = opensdg_translate_key(key, translations, language)
        # If it changed from the key, that means it was a working key.
        if key != translated_part
          part = translated_part
        end

        # Add back the comma if needed.
        if removed_comma
          part = part + ','
        end

        translated_parts.push(part)
      end

      return translated_parts.join(' ')
    end
  end
end

Liquid::Template.register_filter(Jekyll::TranslateDate)
