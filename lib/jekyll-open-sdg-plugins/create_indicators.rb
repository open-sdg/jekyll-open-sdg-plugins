require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class CreateIndicators < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      # If site.create_indicators is set, create indicators per the metadata.
      if site.config['languages'] and site.config['create_indicators']
        # Decide what layout to use for the indicator pages.
        layout = 'indicator'
        if site.config['create_indicators'].key?('layout')
          layout = site.config['create_indicators']['layout']
        end
        # See if we need to "map" any language codes.
        languages_public = Hash.new
        if site.config['languages_public']
          languages_public = opensdg_languages_public(site)
        end
        # Loop through the languages.
        site.config['languages'].each_with_index do |language, index|
          # Get the "public language" (for URLs) which may be different.
          language_public = language
          if languages_public[language]
            language_public = languages_public[language]
          end
          metadata = {}
          if opensdg_translated_builds(site)
            # If we are using translated builds, the metadata is underneath a
            # language code.
            metadata = site.data[language]['meta']
          else
            # Otherwise the 'meta' data is not underneath any language code.
            metadata = site.data['meta']
          end
          # Loop through the indicators (using metadata as a list).
          metadata.each do |inid, meta|
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? inid : File.join(language_public, inid)
            # Create the indicator page.
            site.collections['indicators'].docs << IndicatorPage.new(site, site.source, dir, inid, language, layout)
          end
        end
        # Create the indicator configuration pages.
        if site.config['create_config_forms']
          metadata = {}
          layout = 'config-builder'
          if site.config['create_config_forms'].key?('layout')
            layout = site.config['create_config_forms']['layout']
          end
          if opensdg_translated_builds(site)
            if site.data.has_key?('untranslated')
              metadata = site.data['untranslated']['meta']
            else
              default_language = site.config['languages'][0]
              metadata = site.data[default_language]['meta']
            end
          else
            metadata = site.data['meta']
          end
          # Loop through the indicators (using metadata as a list).
          if !metadata.empty?
            site.config['show_indicator_config_forms'] = true
            # Loop through the languages.
            site.config['languages'].each_with_index do |language, index|
              # Get the "public language" (for URLs) which may be different.
              language_public = language
              if languages_public[language]
                language_public = languages_public[language]
              end
              metadata.each do |inid, meta|
                dir = File.join('config', inid)
                if index != 0
                  dir = File.join(language_public, 'config', inid)
                end
                site.collections['pages'].docs << IndicatorConfigPage.new(site, site.source, dir, inid, language, meta, layout)
              end
            end
          end
        end
      end
    end
  end

  # A Page subclass used in the `CreateIndicators` class.
  class IndicatorPage < Jekyll::Page
    def initialize(site, base, dir, inid, language, layout)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = {}
      self.data['indicator_number'] = inid.gsub('-', '.')
      self.data['layout'] = layout
      self.data['language'] = language
      # Backwards compatibility:
      self.data['indicator'] = self.data['indicator_number']
    end
  end

  # A Page subclass used in the `CreateIndicators` class.
  class IndicatorConfigPage < Jekyll::Page
    def initialize(site, base, dir, inid, language, meta, layout)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = {}
      self.data['language'] = language
      self.data['indicator_number'] = inid.gsub('-', '.')
      self.data['config_type'] = 'indicator'
      self.data['layout'] = layout
      self.data['meta'] = meta
      self.data['title'] = 'Open SDG indicator configuration: ' + self.data['indicator_number']
      self.data['config_filename'] = inid + '.yml'
    end
  end
end
