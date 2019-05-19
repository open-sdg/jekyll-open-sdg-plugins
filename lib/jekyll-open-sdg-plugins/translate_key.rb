require "jekyll"
require_relative "helpers"

module Jekyll
  module TranslateKey
    # Takes a translation key and returns a translated string according to the
    # language of the current page. Or if none is found, returns the original
    # key.
    def t(key)

      # Determine the language of the current page.
      translations = @context.registers[:site].data['translations']
      language = @context.environments.first["page"]['language']

      return opensdg_translate_key(key, translations, language)
    end
  end
end

Liquid::Template.register_filter(Jekyll::TranslateKey)
