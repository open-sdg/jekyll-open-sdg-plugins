require "jekyll"
require 'json'
require 'deep_merge'
require 'open-uri'

module JekyllOpenSdgPlugins
  class TranslatedBuilds < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      if site.config['translated_builds']
        # If using translated builds, consolidate all the translations into on
        # place.
        site.config['languages'].each do |language|
          if !site.data.has_key?('translations')
            site.data['translations'] = {}
          end
          target = site.data['translations'][language]
          source = site.data[language]['translations']
          if target
            target.deep_merge(source)
          else
            site.data['translations'][language] = source
          end
        end
      end
    end
  end
end
