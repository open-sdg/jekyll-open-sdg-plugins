require "jekyll"
require_relative "helpers"

module Jekyll
  module TranslateKey
    # Takes a translation key and returns a translated string according to the
    # language of the current page. Or if none is found, returns the original
    # key.
    def t(key)

      # Determine the language of the current page.
      site = @context.registers[:site]
      translations = site.data['translations']
      language = @context.environments.first["page"]['language']

      translated = opensdg_translate_key(key, translations, language)
      if translated == key
        # If nothing changed, also check for parameters within
        # the content.
        translated = translated.gsub(/^(%+)\w+/) do |m|
          # Remove periods that may be at the end.
          m = m.delete_suffix('.')
          # Check to see if it is a site configuration.
          m = opensdg_parse_site_config(m, site)
          # Check to see if it is a translation key.
          m = opensdg_translate_key(m, translations, language)
          return m
        end
      end

      return translated
    end
  end
end

Liquid::Template.register_filter(Jekyll::TranslateKey)
