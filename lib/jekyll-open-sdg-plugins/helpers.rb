# Simple collection of helper functions for use in these plugins.

require "jekyll"

# Takes a translation key and returns a translated string according to the
# language of the current page. Or if none is found, returns the original
# key.
def opensdg_translate_key(key, translations, language)

  # Safety code - abort now if key is nil.
  if key.nil?
    return ""
  end

  # Also make sure it is a string, and other just return it.
  if not key.is_a? String
    return key
  end

  # More safety code - abort now if key is empty.
  if key.empty?
    return ""
  end

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

# Takes a site object and decides whether it is using translated builds.
def opensdg_translated_builds(site)
  # Assume the site is using translated builds.
  translated_builds = true
  site.config['languages'].each do |language|
    # If any languages don't have a key in site.data, the site is not using
    # translated builds.
    if !site.data.has_key? language
      translated_builds = false
    end
  end
  return translated_builds
end

# Print a notice during compilation.
def opensdg_notice(message)
  Jekyll.logger.warn message.yellow
end

# Get the public language codes for a site, keyed by the actual language codes.
def opensdg_languages_public(site)
  languages_public = site.config['languages_public']

  # The current structure of the setting is an array of hashes, each containing
  # keys for "language" and "public".
  if languages_public.is_a?(Array)
    converted_languages_public = Hash.new
    languages_public.each do |language_public|
      language_code = language_public['language']
      language_code_public = language_public['public']
      converted_languages_public[language_code] = language_code_public
    end
    return converted_languages_public
  end

  # Fallback to exactly what was retrieved from site.confg['languages_public'],
  # since the deprecated structure is exactly what this function wants.
  return languages_public
end
