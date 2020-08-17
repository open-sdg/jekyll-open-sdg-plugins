require "jekyll"
require_relative "helpers"
require "json"
require "json_schemer"

module JekyllOpenSdgPlugins
  class ValidateConfig < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)

      schema_path = File.join(File.dirname(__FILE__), 'config-schema.json')
      json_from_file = File.read(schema_path)
      schema = JSON.parse(json_from_file)
      schemer = JSONSchemer.schema(schema)

      # Perform validation if the "validate_configuration" flag is true.
      if site.config.has_key?('validate_configuration') && site.config['validate_configuration']
        unless schemer.valid?(site.config)
          errors = schemer.validate(site.config).to_a
          errors.each do |error|
            if error['type'] == 'required'
              missing = []
              error['schema']['required'].each do |required_property|
                unless error['data'].has_key?(required_property)
                  message = 'Missing configuration setting: ' + required_property
                  if error['schema'].has_key?('title')
                    message += ' (' + error['schema']['title'] + ')'
                  end
                  opensdg_notice(message)
                end
              end
            else
              message = 'Validation error of type: ' + error['type']
              if error['schema'] && error['schema'].has_key?('title')
                message += ' (' + error['schema']['title'] + ')'
              end
              opensdg_notice(message)
              if error['schema']
                opensdg_notice('Expected schema:')
                puts error['schema'].inspect
              end
              if error['data']
                opensdg_notice('Actual data:')
                puts error['data'].inspect
              end
            end
          end
          opensdg_notice "The site configuration is not valid. See feedback above."
          raise "Invalid site configuration"
        end
      end

      # Regardless place the schema in site data so it can be used in Jekyll templates.
      site.data['config-schema'] = schema

    end
  end
end
