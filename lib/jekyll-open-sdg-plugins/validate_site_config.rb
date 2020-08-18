require "jekyll"
require_relative "helpers"
require "json"
require "json_schemer"

module JekyllOpenSdgPlugins
  class ValidateSiteConfig < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)

      schema_path = File.join(File.dirname(__FILE__), 'schema-site-config.json')
      json_from_file = File.read(schema_path)
      schema = JSON.parse(json_from_file)
      schemer = JSONSchemer.schema(schema)

      # Perform validation if the "validate_site_config" flag is true.
      if site.config.has_key?('validate_site_config') && site.config['validate_site_config']
        unless schemer.valid?(site.config)
          opensdg_notice('Site configuration invalid:')
          errors = schemer.validate(site.config).to_a
          errors.each { |error| opensdg_validation_error(error) }
          opensdg_notice "The site configuration is not valid. See feedback above."
          raise "Invalid site configuration"
        end
      end

      # Regardless place the schema in site data so it can be used in Jekyll templates.
      site.data['schema-site-config'] = schema

    end
  end
end
