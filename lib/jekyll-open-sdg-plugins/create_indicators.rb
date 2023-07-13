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
      form_settings_config = site.config['indicator_config_form']
      form_settings_meta = site.config['indicator_metadata_form']
      form_settings_data = site.config['indicator_data_form']

      translations = site.data['translations']
      # If site.create_indicators is set, create indicators per the metadata.
      if (language_config and indicator_config)
        # Decide what layout to use for the indicator pages.
        layout = 'indicator'
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
          metadata = site.data[language]['meta']
          # Loop through the indicators (using metadata as a list).
          metadata.each do |inid, meta|
            permalink = inid
            if (meta.has_key?('permalink') and meta['permalink'] != '')
              permalink = meta['permalink']
            end
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? permalink : File.join(language_public, permalink)

            # Create the indicator page.
            site.collections['indicators'].docs << IndicatorPage.new(site, site.source, dir, inid, language, layout)
            # Also create the iframe version.
            iframe_layout = 'indicator-iframe'
            iframe_permalink = permalink + '-iframe'
            iframe_dir = index == 0 ? iframe_permalink : File.join(language_public, iframe_permalink)
            site.collections['pages'].docs << IndicatorPage.new(site, site.source, iframe_dir, inid, language, iframe_layout)
          end
        end
        # Create the indicator settings configuration/metadata/data pages.
        do_indicator_config_forms = form_settings_config && form_settings_config['enabled']
        do_indicator_meta_forms = form_settings_meta && form_settings_meta['enabled']
        do_indicator_data_forms = form_settings_data && form_settings_data['enabled']
        use_translated_metadata = form_settings_meta && form_settings_meta['translated']
        if do_indicator_config_forms || do_indicator_meta_forms || do_indicator_data_forms

          metadata = {}
          
          if site.data.has_key?('untranslated')
            metadata = site.data['untranslated']['meta']
          else
            default_language = language_config[0]
            metadata = site.data[default_language]['meta']
          end

          metadata_by_language = {}
          language_config.each do |language|
            metadata_by_language[language] = site.data[language]['meta']
          end

          # Because we have config forms for indicator config or meta/data, we
          # take over the meta/data_edit_url and configuration_edit_url settings
          # here with simple relative links.
          if do_indicator_config_forms
            site.config['configuration_edit_url'] = 'config'
          end

          if do_indicator_meta_forms
            site.config['metadata_edit_url'] = 'metadata'
          end

          if do_indicator_data_forms
            site.config['data_edit_url'] = 'data'
          end

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
                if (meta.has_key?('permalink') and meta['permalink'] != '')
                  permalink = meta['permalink']
                end
                dir_base = File.join(permalink)
                if index != 0
                  dir_base = File.join(language_public, permalink)
                end

                if do_indicator_config_forms
                  dir = File.join(dir_base, 'config')
                  title = opensdg_translate_key('indicator.edit_configuration', translations, language)
                  config_type = 'indicator'
                  site.collections['pages'].docs << IndicatorConfigPage.new(site, site.source, dir, inid, language, meta, title, config_type, form_settings_config)
                end

                if do_indicator_meta_forms
                  metadata_to_use = meta
                  if use_translated_metadata
                    metadata_to_use = metadata_by_language[language][inid]
                  end
                  dir = File.join(dir_base, 'metadata')
                  title = opensdg_translate_key('indicator.edit_metadata', translations, language)
                  config_type = 'metadata'
                  site.collections['pages'].docs << IndicatorConfigPage.new(site, site.source, dir, inid, language, metadata_to_use, title, config_type, form_settings_meta)
                end

                if do_indicator_data_forms
                  dir = File.join(dir_base, 'data')
                  title = opensdg_translate_key('indicator.edit_data', translations, language)
                  site.collections['pages'].docs << IndicatorDataPage.new(site, site.source, dir, inid, language, title, form_settings_data)
                end
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
    end
  end

  # A Page subclass used in the `CreateIndicators` class for the indicator config forms.
  class IndicatorConfigPage < Jekyll::Page
    def initialize(site, base, dir, inid, language, meta, title, config_type, form_settings)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = {}
      self.data['language'] = language
      self.data['indicator_number'] = inid
      self.data['config_type'] = config_type
      self.data['layout'] = 'config-builder'
      self.data['meta'] = meta
      self.data['title'] = title + ': ' + inid.gsub('-', '.')
      self.data['config_filename'] = inid + '.yml'
      self.data['form_settings'] = form_settings
    end
  end

  # A Page subclass used in the `CreateIndicators` class for the indicator data forms.
  class IndicatorDataPage < Jekyll::Page
    def initialize(site, base, dir, inid, language, title, form_settings)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      self.process(@name)
      self.data = {}
      self.data['language'] = language
      self.data['indicator_number'] = inid
      self.data['layout'] = 'data-editor'
      self.data['title'] = title + ': ' + inid.gsub('-', '.')
      self.data['config_filename'] = 'indicator_' + inid
      self.data['form_settings'] = form_settings
    end
  end
end
