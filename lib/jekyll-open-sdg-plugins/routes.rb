require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class Routes < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)

      routes = {}
      baseurl = ''
      if site.config.has_key?('baseurl') and site.config['baseurl'].is_a?(String)
        baseurl = site.config['baseurl']
      end
      unless baseurl.end_with?('/')
        baseurl = baseurl + '/'
      end

      routes['pages'] = []
      site.collections['pages'].docs.each do |doc|
        route = baseurl + doc.url
        route = route.gsub('//', '/')

        unless route.end_with?('/') or route.end_with?('.html') or route.end_with?('.json')
          route = route + '/'
        end

        unless doc.data['layout'] == 'config-builder' or doc.data['layout'] == 'data-editor' or doc.data['layout'] == 'config-builder-2'
          routes['pages'].append(route)
        end
      end

      routes['config'] = []
      site.collections['pages'].docs.each do |doc|
        route = baseurl + doc.url
        route = route.gsub('//', '/')

        unless route.end_with?('/') or route.end_with?('.html') or route.end_with?('.json')
          route = route + '/'
        end

        if doc.data['layout'] == 'config-builder' or doc.data['layout'] == 'data-editor' or doc.data['layout'] == 'config-builder-2'
          routes['config'].append(route)
        end
      end

      routes['indicators'] = []
      site.collections['indicators'].docs.each do |doc|
        route = baseurl + doc.url
        route = route.gsub('//', '/')

        unless route.end_with?('/') or route.end_with?('.html') or route.end_with?('.json')
          route = route + '/'
        end
        routes['indicators'].append(route)
      end

      routes['goals'] = []
      site.collections['goals'].docs.each do |doc|
        route = baseurl + doc.url
        route = route.gsub('//', '/')

        unless route.end_with?('/') or route.end_with?('.html') or route.end_with?('.json')
          route = route + '/'
        end
        routes['goals'].append(route)
      end

      routes['posts'] = []
      site.collections['posts'].docs.each do |doc|
        route = baseurl + doc.url
        route = route.gsub('//', '/')

        unless route.end_with?('/') or route.end_with?('.html') or route.end_with?('.json')
          route = route + '/'
        end
        routes['posts'].append(route)
      end

      routes['images'] = []
      if site.config.has_key?('logos') and site.config['logos'].length > 0
        site.config['logos'].each do |logo|
          route = baseurl + logo['src']
          routes['images'].append(route)
        end
      end

      goal_image_base = 'https://open-sdg.org/sdg-translations/assets/img/goals'
      if site.config.has_key?('goal_image_base')
        goal_image_base = site.config['goal_image_base']
      end
      goal_image_extension = 'png'
      if site.config.has_key?('goal_image_extension') && site.config['goal_image_extension'] != ''
        goal_image_extension = site.config['goal_image_extension']
      end
      goal_image_base_contrast = goal_image_base.gsub('img/goals', 'img/high-contrast/goals')

      site.collections['goals'].docs.each do |doc|
        goal_number = doc.data['goal']['number']
        language = doc.data['language']
        if goal_number.is_a? Numeric
          goal_number = goal_number.to_s
        end
        route = goal_image_base + '/' + language + '/' + goal_number + '.' + goal_image_extension
        routes['images'].append(route)
        unless goal_image_extension == 'svg'
          route = goal_image_base_contrast + '/' + language + '/' + goal_number + '.' + goal_image_extension
          routes['images'].append(route)
        end
      end

      data_prefix = site.config['remote_data_prefix']
      unless data_prefix.start_with?('http')
        data_prefix = baseurl
      end
      unless data_prefix.end_with?('/')
        data_prefix = data_prefix + '/'
      end

      routes['json'] = []
      routes['csv'] = []
      routes['zip'] = []
      site.config['languages'].each do |language|
        site.collections['indicators'].docs.each do |doc|
          route = data_prefix + language + '/comb/' + doc.data['indicator']['slug'] + '.json'
          routes['json'].append(route)
          route = data_prefix + language + '/data/' + doc.data['indicator']['slug'] + '.csv'
          routes['csv'].append(route)
        end
        route = data_prefix + language + '/zip/' + site.data[language]['zip']['filename']
        routes['zip'].append(route)
      end

      site.data['routes'] = routes
    end
  end
end
