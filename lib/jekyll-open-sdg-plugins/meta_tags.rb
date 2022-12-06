require "jekyll"

module JekyllOpenSdgPlugins
  class MetaTags < Jekyll::Generator
    safe true
    priority :lowest

    def clean_path(path)
      path.delete_prefix('/').delete_suffix('/')
    end

    def find_metatags_by_path(path, config)
      config.select { |tag| clean_path(tag['path']) == path }
    end

    def generate(site)

      # Some general variables needed below.
      languages = site.config['languages']
      default_language = languages[0]

      if site.config.has_key?('meta_tags')
        site.collections.keys.each do |collection|
          if collection == 'pages'
            site.collections[collection].docs.each do |doc|
              cleaned_path = clean_path(doc.data['url_by_language'][default_language])
              meta_tags = find_metatags_by_path(cleaned_path, site.config['meta_tags'])
              doc.data['meta_tags'] = meta_tags
            end
          end
        end
      end
    end
  end
end
