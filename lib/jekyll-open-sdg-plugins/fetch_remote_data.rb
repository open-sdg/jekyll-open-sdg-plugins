require "jekyll"
require 'json'
require 'deep_merge'
require 'open-uri'
require_relative "helpers"

module JekyllOpenSdgPlugins
  class FetchRemoteData < Jekyll::Generator
    safe true
    priority :highest

    # Fix a Unix path in case we are on Windows.
    def fix_path(path)
      path_parts = path.split('/')
      return path_parts.join(File::SEPARATOR)
    end

    # Our hardcoded list of pieces of the build that we expect.
    def get_endpoints()
      return {
        'meta' => 'meta/all.json',
        'headlines' => 'headline/all.json',
        'schema' => 'meta/schema.json',
        'reporting' => 'stats/reporting.json',
        'disaggregation' => 'stats/disaggregation.json',
        'translations' => 'translations/translations.json',
        'zip' => 'zip/all_indicators.json',
        'indicator_downloads' => 'downloads/indicator-downloads.json',
        'data_packages' => 'data-packages/all.json',
      }
    end

    # Get a build from a local folder on disk or a remote URL on the Internet.
    def fetch_build(path)

      is_remote = opensdg_is_path_remote(path)
      build = {}
      get_endpoints().each do |key, value|
        endpoint = is_remote ? path + '/' + value : File.join(path, fix_path(value))

        begin
          json_file = is_remote ? URI.open(endpoint) : File.open(endpoint)
          build[key] = JSON.load(json_file)
        rescue StandardError => e
          # For backwards compatibility, forego the exception in some cases.
          abort_build = true
          if ['translations', 'indicator_downloads', 'disaggregation', 'data_packages'].include? key
            abort_build = false
          elsif endpoint.include? '/untranslated/'
            abort_build = false
          end
          if abort_build
            puts e.message
            abort 'Unable to read data from: ' + endpoint
          end
        end
      end

      return build
    end

    def generate(site)

      # For below, make sure there is at least an empty hash at
      # site.data.translations.
      if !site.data.has_key?('translations')
        site.data['translations'] = {}
      end

      remote = site.config['remote_data_prefix']
      local = site.config['local_data_folder']

      if !remote && !local
        abort 'Site config must include "remote_data_prefix".'
      end

      build_location = remote ? remote : local
      is_remote = opensdg_is_path_remote(build_location)

      build_location = is_remote ? build_location : File.join(Dir.pwd, build_location)

      # We get a build for each language, and place them in "subfolders"
      # (so to speak) of site.data.
      subfolders = site.config['languages'].clone
      subfolders.append('untranslated')
      subfolders.each do |language|
        data_target = site.data[language]
        translated_build = is_remote ? build_location + '/' + language : File.join(build_location, language)
        data_source = fetch_build(translated_build)
        if !data_source.empty?
          if data_target
            data_target.deep_merge(data_source)
          else
            site.data[language] = data_source
          end
        end
      end
      # We move the language-specific translations to the
      # site.data.translations location, where all translations are kept.
      site.config['languages'].each do |language|
        translation_target = site.data['translations'][language]
        translation_source = site.data[language]['translations']
        if translation_target
          translation_target.deep_merge(translation_source)
        else
          site.data['translations'][language] = translation_source
        end
      end
      # And there are some parts of the build that don't need to be translated
      # and should be moved to the top level.
      first_language = site.config['languages'][0]
      site.data['reporting'] = site.data[first_language]['reporting']
      site.data['schema'] = site.data[first_language]['schema']
      site.data['zip'] = site.data[first_language]['zip']
    end
  end

  # This makes sure that the contents of any local data build get copied
  # into the Jekyll build, so that they can be served from the website.
  Jekyll::Hooks.register :site, :post_write do |site|
    if site.config['remote_data_prefix']
      if !opensdg_is_path_remote(site.config['remote_data_prefix'])
        source = File.join(Dir.pwd, site.config['remote_data_prefix'], '.')
        destination = site.config['destination']
        FileUtils.cp_r(source, destination)
      end
    end
  end
end
