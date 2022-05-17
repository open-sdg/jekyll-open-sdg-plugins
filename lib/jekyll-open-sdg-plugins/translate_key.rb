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
      # Also look for references to site configuration within the translation,
      # as "%" parameters.
      translated = translated.gsub(/%([a-zA-Z0-9_.\-]+)/) do |match|
        # Special case for trailing dots.
        trailing_dot = match.end_with?('.')
        key_candidate = match.delete_suffix('.').delete_prefix('%')
        # Check to see if it is a site configuration.
        translated_word = opensdg_parse_site_config(key_candidate, site)
        # Check to see if the value of the site config may have been
        # a translation key itself. But do a safety check to avoid
        # infinite loops.
        if translated_word != key
          translated_word = opensdg_translate_key(translated_word, translations, language)
        end
        # Replace the word if something changed.
        if key_candidate != translated_word
          match = translated_word
          # Making sure to add back any trailing dots.
          if trailing_dot
            match = match + '.'
          end
        end
        match
      end

      return translated
    end
  end
end

Liquid::Template.register_filter(Jekyll::TranslateKey)
