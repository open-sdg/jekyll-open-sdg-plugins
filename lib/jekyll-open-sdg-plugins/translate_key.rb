require "jekyll"

module Jekyll
  module TranslateKey
    # Takes a translation key and returns a translated string according to the
    # language of the current page. Or if none is found, returns the original
    # key.
    def t(key)

      # Safety code - abort now if key is nil.
      if key.nil?
        return ""
      end

      # Determine the language of the current page.
      translations = @context.registers[:site].data['translations']
      language = @context.environments.first["page"]['language']

      # Keep track of the last thing we drilled to.
      drilled = translations[language]

      # Keep track of how many levels we have drilled.
      levels_drilled = 0
      levels = key.split('.')

      # Loop through each level.
      levels.each do |level|

        # If we have drilled down to a scalar value too soon, abort.
        break if drilled.class != Hash

        if drilled.has_key? level
          # If we find something, continue drilling.
          drilled = drilled[level]
          levels_drilled += 1
        end

      end

      # If we didn't drill the right number of levels, return the
      # original string.
      if levels.length != levels_drilled
        return key
      end

      # Otherwise we must have drilled all they way.
      return drilled
    end
  end
end

Liquid::Template.register_filter(Jekyll::TranslateKey)
