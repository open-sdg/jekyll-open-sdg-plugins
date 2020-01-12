require "jekyll"

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
            'layout' => 'reportingstatus'
          },
          {
            'filename' => 'indicators.json',
            'folder' => '/',
            'layout' => 'indicator-json',
          },
          {
            'folder' => '/search',
            'layout' => 'search'
          }
        ]
        pages = default_pages
        if site.config['create_pages'].is_a?(Hash) and site.config['create_pages'].key?('pages')
          pages = site.config['create_pages']['pages']
        end

        # See if we need to "map" any language codes.
        languages_public = Hash.new
        if site.config['languages_public']
          languages_public = site.config['languages_public']
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
      self.data['layout'] = page['layout']
      self.data['language'] = language
    end
  end
end
