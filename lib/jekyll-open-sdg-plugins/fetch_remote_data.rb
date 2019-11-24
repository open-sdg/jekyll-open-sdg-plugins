require "jekyll"
require 'json'
require 'deep_merge'
require 'open-uri'
require_relative "helpers"

module JekyllOpenSdgPlugins
  class FetchRemoteData < Jekyll::Generator
    safe true
    priority :highest

    def download_build(prefix)
      endpoints = {
        'meta' => 'meta/all.json',
        'headlines' => 'headline/all.json',
        'schema' => 'meta/schema.json',
        'reporting' => 'stats/reporting.json',
        'translations' => 'translations/translations.json'
      }
      build = {}
      endpoints.each do |key, value|
        endpoint = prefix + '/' + value
        begin
          source = JSON.load(open(endpoint))
          build[key] = source
        rescue StandardError => e
          puts e.message
          abort 'Unable to fetch remote data from: ' + endpoint
        end
      end
      build
    end

    def generate(site)

      if site.config['remote_data_prefix']
        prefix = site.config['remote_data_prefix']

        # For below, make sure there is at least an empty hash at
        # site.data.translations.
        if !site.data.has_key?('translations')
          site.data['translations'] = {}
        end

        if opensdg_translated_builds(site)
          # For translated builds, we download a build for each language, and
          # place them in "subfolders" (so to speak) of site.data.
          site.config['languages'].each do |language|
            data_target = site.data[language]
            data_source = download_build(prefix + '/' + language)
            if data_target
              data_target.deep_merge(data_source)
            else
              site.data[language] = data_source
            end
            # Additionally, we move the language-specific translations to the
            # site.data.translations location, where all translations are kept.
            translation_target = site.data['translations'][language]
            translation_source = site.data[language]['translations']
            if translation_target
              translation_target.deep_merge(translation_source)
            else
              site.data['translations'][language] = translation_source
            end
          end
        else
          # For untranslated builds, we download one build only, and place it
          # in the "root" (so to speak) of site.data. Nothing else is needed.
          target = site.data
          source = download_build(prefix)
          target.deep_merge(source)
        end
      else
        abort 'The "remote_data_prefix" configuration setting is missing.'
      end

      # Finally support the deprecated 'remote_translations' option.
      # This is deprecated because translations should now be in the
      # data repository, where they will be fetched in download_build().
      if site.config['remote_translations']
        key = 'translations'
        target = site.data[key]
        site.config['remote_translations'].each do |endpoint|
          begin
            source = JSON.load(open(endpoint))
            if target
              target.deep_merge(source)
            else
              site.data[key] = source
            end
          rescue StandardError => e
            puts e.message
            abort 'Unable to fetch remote translation from: ' + endpoint
          end
        end
      end
    end
  end
end
