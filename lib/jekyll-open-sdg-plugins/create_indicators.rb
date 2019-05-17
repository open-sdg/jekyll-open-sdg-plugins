require "jekyll"

module JekyllOpenSdgPlugins
  class CreateIndicators < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      # If site.create_indicators is set, create indicators per the metadata.
      if site.config['languages'] and site.config['create_indicators']
        # Decide what layout to use for the indicator pages.
        layout = 'indicator'
        if site.config['create_indicators'].key?('layout')
          layout = site.config['create_indicators']['layout']
        end
        # Loop through the languages.
        site.config['languages'].each_with_index do |language, index|
          # Loop through the indicators (using metadata as a list).
          site.data['meta'].each do |inid, meta|
            # Add the language subfolder for all except the default (first) language.
            dir = index == 0 ? inid : File.join(language, inid)
            # Create the indicator page.
            site.collections['indicators'].docs << IndicatorPage.new(site, site.source, dir, inid, language, layout)
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
      self.data['indicator'] = inid.gsub('-', '.')
      self.data['layout'] = layout
      self.data['language'] = language
    end
  end
end
