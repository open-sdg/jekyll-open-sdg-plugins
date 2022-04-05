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
          json_file = is_remote ? open(endpoint) : File.open(endpoint)
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

    # Predict (before data has been fetched) whether the site is using
    # translated builds or not.
    def site_uses_translated_builds(path)

      is_remote = opensdg_is_path_remote(path)
      endpoints = get_endpoints()
      # For a quick test, we just use 'meta'.
      meta = endpoints['meta']
      endpoint = is_remote ? path + '/' + meta : File.join(path, fix_path(meta))

      begin
        json_file = is_remote ? open(endpoint) : File.open(endpoint)
      rescue StandardError => e
        # If we didn't find an untranslated 'meta', we assume translated builds.
        return true
      end

      # Other wise assume untranslated builds.
      return false
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
      translated_builds = site_uses_translated_builds(build_location)

      if translated_builds
        # For translated builds, we get a build for each language, and
        # place them in "subfolders" (so to speak) of site.data.
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
      else
        # For untranslated builds, we download one build only, and place it
        # in the "root" (so to speak) of site.data. Nothing else is needed.
        target = site.data
        source = fetch_build(build_location)
        if !source.empty?
          target.deep_merge(source)
        end
      end

      # Finally support the deprecated 'remote_translations' option.
      # This is deprecated because translations should now be in the
      # data repository, where they will be fetched in fetch_build().
      if site.config['remote_translations']
        opensdg_notice(
          <<~HEREDOC
          DEPRECATION NOTICE: In Open SDG 2.0.0, the 'remote_translations' setting will
          be removed. Translations are now managed in the data configuration, instead of
          the site configuration. Please update your platform accordingly. You can use
          the open-sdg/open-sdg-data-starter repository as a guide."
          HEREDOC
        )
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

  # This makes sure that the contents of the "local_data_folder" get copied
  # into the Jekyll build, so that they can be served from the website.
  Jekyll::Hooks.register :site, :post_write do |site|
    if site.config['local_data_folder']
      opensdg_notice(
        <<~HEREDOC
        DEPRECATION NOTICE: In Open SDG 2.0.0, the 'local_data_folder' setting will
        be removed. Instead please use the 'remote_data_prefix' setting. It can
        contain exactly what you previously used in 'local_data_folder'.
        HEREDOC
      )
      source = File.join(Dir.pwd, site.config['local_data_folder'], '.')
      destination = site.config['destination']
      FileUtils.cp_r(source, destination)
    # Do the same in the case that "remote_data_prefix" is being used for a local
    # data folder (since "local_data_folder" is deprecated and undocumented).
    elsif site.config['remote_data_prefix']
      if !opensdg_is_path_remote(site.config['remote_data_prefix'])
        source = File.join(Dir.pwd, site.config['remote_data_prefix'], '.')
        destination = site.config['destination']
        FileUtils.cp_r(source, destination)
      end
    end
  end
end
