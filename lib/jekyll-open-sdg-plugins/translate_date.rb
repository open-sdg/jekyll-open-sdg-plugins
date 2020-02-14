require "jekyll"
require_relative "helpers"

module Jekyll
  module TranslateDate

    # Takes a raw Jekyll date and returns a translated string according to the
    # language of the current page and a date format given.
    def t_date(date, format_type)

      # Determine the language of the current page.
      config = @context.registers[:site].config
      translations = @context.registers[:site].data['translations']
      language = @context.environments.first['page']['language']

      # Try to find the specified date format in the site config. It needs to be
      # something like this, assuming the "format_type" param is "standard":
      # date_formats:
      #   standard:
      #     en: "%b %d, %Y"
      #     es: "%d de %b de %Y"
      #     etc...
      date_format = '%b %d, %Y'
      if config.has_key? 'date_formats'
        if config['date_formats'].has_key? format_type
          if config['date_formats'][format_type].has_key? language
            date_format = config['date_formats'][format_type][language]
          end
        end
      end

      # Support timestamps.
      if date.is_a? Integer
        date = Time.at(date)
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
