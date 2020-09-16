require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class SearchIndex < Jekyll::Generator
    safe true
    priority :lowest
    # NOTE: This must be executed **after** the sdg_variables.rb file, since it
    # relies heavily on the variables created there.

    # Helper function to prepare content for the search index.
    def prepare_content(site, content)

      # Handle nil content.
      if !content
        content = ''
      end

      # First compile any Markdown.
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
      content = converter.convert(content)
      # Now strip any HTML.
      content = content.gsub(/<\/?[^>]*>/, "")
      return content
    end

    def generate(site)

      # Generate a hash of items to include in the search index.
      search_items = {}

      site.collections.keys.each do |collection|
        site.collections[collection].docs.each do |doc|
          # We segregate the search items by language.
          language = doc.data['language']
          if !search_items.has_key? language
            search_items[language] = {}
          end
          # We'll be adding properties to this basic hash.
          item = {
            # The 'type' can be used on the front-end to describe a search result.
            # It is assumed that all the collection names are translated in the
            # "general" translation group. Eg: general.indicators, general.goals
            'type' => opensdg_translate_key('general.' + collection, site.data['translations'], language)
          }
          if collection == 'indicators'
            # For indicators, we assign the following properties for each item.
            # The URL of the page.
            item['url'] = doc.data['indicator']['url']
            # For the title, use the indicator name.
            item['title'] = doc.data['indicator']['number'] + ' ' + doc.data['indicator']['name']
            # For the content, use the 'page_content' field.
            item['content'] = prepare_content(site, doc.data['indicator']['page_content'])
            # For the id field, use the ID number.
            item['id'] = doc.data['indicator']['number']
            # Also index any additional metadata fields.
            if site.config['search_index_extra_fields']
              site.config['search_index_extra_fields'].each do |field|
                if doc.data['indicator'].has_key? field
                  item[field] = prepare_content(site, doc.data['indicator'][field])
                end
              end
            end
          elsif collection == 'goals'
            # For goals, we assign the following properties for each item.
            # The URL of the page.
            item['url'] = doc.data['goal']['url']
            # For the title we use the goal name.
            goal_label = opensdg_translate_key('general.goal', site.data['translations'], language)
            item['title'] = goal_label + ' ' + doc.data['goal']['number'] + ' ' + doc.data['goal']['name']
            # For the content, currently nothing here.
            item['content'] = ''
            # For the id field, use the ID number.
            item['id'] = doc.data['goal']['number']
          else
            # Otherwise assume it is a normal Jekyll document.
            item['url'] = File.join(doc.data['baseurl'], doc.url)
            item['title'] = doc.data['title']
            item['content'] = prepare_content(site, doc.content)
            item['id'] = ''
          end

          # Save this item in the language-specific search index.
          search_items[language][item['url']] = item
        end
      end

      # Stow the data for later use in Jekyll templates.
      site.data['search_items'] = search_items

    end
  end
end
