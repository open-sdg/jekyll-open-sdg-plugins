require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class CreateIndicators < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      # Some references to clean up the code below.
      language_config = site.config['languages']
      indicator_config = site.config['create_indicators']
      form_config = site.config['create_config_forms']
      translations = site.data['translations']
      # If site.create_indicators is set, create indicators per the metadata.
      if language_config and indicator_config and indicator_config.key?('layout') and indicator_config['layout'] != ''
        # Decide what layout to use for the indicator pages.
        layout = indicator_config['layout']
        # See if we need to "map" any language codes.
        languages_public = Hash.new
        if site.config['languages_public']
          languages_public = opensdg_languages_public(site)
        end
        # Loop through the languages.
        language_config.each_with_index do |language, index|
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
            permalink = inid
            if meta.has_key?('permalink') and meta['permalink'] != ''
              permalink = meta['permalink']
            end
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? permalink : File.join(language_public, permalink)

            # Create the indicator page.
            site.collections['indicators'].docs << IndicatorPage.new(site, site.source, dir, inid, language, layout)
          end
        end
        # Create the indicator settings configuration pages.
        if form_config && form_config.key?('layout') && form_config['layout'] != ''

          layout = form_config['layout']
          metadata = {}
          if opensdg_translated_builds(site)
            if site.data.has_key?('untranslated')
              metadata = site.data['untranslated']['meta']
            else
              default_language = language_config[0]
              metadata = site.data[default_language]['meta']
            end
          else
            metadata = site.data['meta']
          end

          # Because we have config forms for indicator config and metadata, we
          # take over the metadata_edit_url and configuration_edit_url settings
          # here with simple relative links.
          site.config['metadata_edit_url'] = 'metadata'
          site.config['configuration_edit_url'] = 'config'

          # Loop through the indicators (using metadata as a list).
          if !metadata.empty?
            # Loop through the languages.
            language_config.each_with_index do |language, index|
              # Get the "public language" (for URLs) which may be different.
              language_public = language
              if languages_public[language]
                language_public = languages_public[language]
              end
              metadata.each do |inid, meta|
                permalink = inid
                if meta.has_key?('permalink') and meta['permalink'] != ''
                  permalink = meta['permalink']
                end
                dir_base = File.join(permalink)
                if index != 0
                  dir_base = File.join(language_public, permalink)
                end

                dir = File.join(dir_base, 'config')
                title = opensdg_translate_key('indicator.edit_configuration', translations, language)
                config_type = 'indicator'
                site.collections['pages'].docs << IndicatorConfigPage.new(site, site.source, dir, inid, language, meta, layout, title, config_type, site.config['indicator_config_form'])

                dir = File.join(dir_base, 'metadata')
                title = opensdg_translate_key('indicator.edit_metadata', translations, language)
                config_type = 'metadata'
                site.collections['pages'].docs << IndicatorConfigPage.new(site, site.source, dir, inid, language, meta, layout, title, config_type, site.config['indicator_metadata_form'])
              end
            end
          end
        end
      end
    end
  end

  # A Page subclass used in the `CreateIndicators` class for the indicators.
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

  # A Page subclass used in the `CreateIndicators` class for the indicator config forms.
  class IndicatorConfigPage < Jekyll::Page
    def initialize(site, base, dir, inid, language, meta, layout, title, config_type, form_settings)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = {}
      self.data['language'] = language
      self.data['indicator_number'] = inid.gsub('-', '.')
      self.data['config_type'] = config_type
      self.data['layout'] = layout
      self.data['meta'] = meta
      self.data['title'] = title + ': ' + self.data['indicator_number']
      self.data['config_filename'] = inid + '.yml'
      self.data['form_settings'] = form_settings
    end
  end
end
