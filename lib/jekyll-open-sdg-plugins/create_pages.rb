require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class CreatePages < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      # If site.create_pages is set, create the 4 required pages. These include:
      # - the home page: /
      # - the indicators json page: /indicators.json
      # - the search results page: /search
      # - the reporting status page: /reporting-status
      #
      # These can be overridden though, with a create_pages.pages setting in
      # _config.yml, like so:
      #
      # create_pages:
      #   pages:
      #     - folder: ''
      #       layout: frontpage
      #     - filename: my-json-file.json
      #       folder: my-subfolder
      #       layout: indicator-json
      #
      # Note the optional "filename" setting for when the page needs a specific
      # filename (as opposed to being "index.html" inside a named folder).
      #
      # To use the default 4 pages, simply put:
      #
      # create_pages: true
      if site.config['languages'] and site.config['create_pages']

        default_pages = [
          {
            'folder' => '/',
            'layout' => 'frontpage'
          },
          {
            'folder' => '/reporting-status',
            'layout' => 'reportingstatus',
            'title' => 'status.reporting_status',
          },
          {
            'filename' => 'indicators.json',
            'folder' => '/',
            'layout' => 'indicator-json',
          },
          {
            'folder' => '/search',
            'layout' => 'search',
            'title' => 'search.search',
          }
        ]
        pages = default_pages
        if site.config['create_pages'].is_a?(Hash) and site.config['create_pages'].key?('pages')
          # Backwards compatability to support the deprecated "pages" key.
          pages = site.config['create_pages']['pages']
        elsif site.config['create_pages'].is_a?(Array)
          pages = site.config['create_pages']
        end

        # Clone pages so that we don't edit the original.
        pages = pages.clone

        # Hardcode the site configuration page if it's not already there.
        config_page = pages.find { |page| page['layout'] == 'config-builder' }
        if config_page == nil
          pages.push({
            'folder' => '/config',
            'layout' => 'config-builder',
            'title' => 'Open SDG site configuration',
            'config_type' => 'site',
            'config_filename' => 'site_config.yml'
          })
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
          # Loop through the pages.
          pages.each do |page|
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? page['folder'] : File.join(language_public, page['folder'])
            # Create the page.
            site.collections['pages'].docs << OpenSdgPage.new(site, site.source, dir, page, language)
          end
        end
      end
    end
  end

  # A Page subclass used in the `CreatePages` class.
  class OpenSdgPage < Jekyll::Page
    def initialize(site, base, dir, page, language)
      @site = site
      @base = base

      index_files = (!page.key?('filename') or page['filename'] == 'index.html')
      @dir = index_files ? File.join(dir, '/') : dir
      @name = index_files ? 'index.html' : page['filename']

      self.process(@name)
      self.data = {}
      self.data['language'] = language

      # Add anything else besides "folder" and "filename". This will catch
      # things like "layout" and "title", and anything else.
      page.each do |key, value|
        if key != 'folder' && key != 'filename'
          self.data[key] = value
        end
      end
    end
  end
end
