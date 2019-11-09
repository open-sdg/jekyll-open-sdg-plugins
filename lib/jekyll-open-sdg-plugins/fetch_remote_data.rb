require "jekyll"
require 'json'
require 'deep_merge'
require 'open-uri'

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
      # Backwards compatibility - only do this if 'jekyll_get_json' is absent.
      # (This is the older style of remote data fetching.)
      if !site.config['jekyll_get_json']
        # First try to grab the remote data.
        if site.config['remote_data_prefix']
          prefix = site.config['remote_data_prefix']
          if site.config['translated_builds']
            site.config['languages'].each do |language|
              target = site.data[language]
              source = download_build(prefix + '/' + language)
              if target
                target.deep_merge(source)
              else
                site.data[language] = source
              end
            end
          else
            target = site.data
            source = download_build(prefix)
            target.deep_merge(source)
          end
          # Set the required remotedatabaseurl config setting.
          site.config['remotedatabaseurl'] = prefix
        end

        # Next try to grab any remote translations.
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
end
