require "jekyll"
require_relative "helpers"
require "json"
require "json_schemer"

module JekyllOpenSdgPlugins
  class ValidateIndicatorConfig < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)

      schema_path = File.join(File.dirname(__FILE__), 'schema-indicator-config.json')
      json_from_file = File.read(schema_path)
      schema = JSON.parse(json_from_file)
      schemer = JSONSchemer.schema(schema)

      # Perform validation if the "validate_indicator_config" flag is true.
      if site.config.has_key?('validate_indicator_config') && site.config['validate_indicator_config']
        # We don't care too much what language we use, just get the first one.
        language = 'en'
        if site.config.has_key?('languages')
          language = site.config['languages'][0]
        end
        metadata = {}
        metadata = site.data[language]['meta']
        # Loop through the indicators (using metadata as a list).
        validation_failed = false
        metadata.each do |inid, meta|
          unless schemer.valid?(meta)
            validation_failed = true
            opensdg_notice('Indicator ' + inid + ' configuration invalid:')
            errors = schemer.validate(meta).to_a
            errors.each { |error| opensdg_validation_error(error) }
          end
        end
        if validation_failed
          opensdg_notice "Some indicator configuration was not valid. See feedback above."
          raise "Invalid indicator configuration"
        end
      end

      # Regardless place the schema in site data so it can be used in Jekyll templates.
      site.data['schema-indicator-config'] = schema

    end
  end
end
