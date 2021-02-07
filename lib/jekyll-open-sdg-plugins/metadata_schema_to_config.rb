require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class MetadataSchemaToConfig < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)

      # Convert the metadata schema from the internal format into JSONSchema so
      # it can be used to create config forms.

      language_config = site.config['languages']
      form_config = site.config['create_config_forms']
      t = site.data['translations']
      lang = language_config[0]

      if form_config && form_config.key?('metadata_scopes') && form_config['metadata_scopes'].length() > 0

        schema = {}
        scopes = []
        form_config['metadata_scopes'].each do |scope|
          schema[scope['key']] = {
            "type" => "object",
            "title" => "Open SDG " + scope['label'],
            "properties" => {},
          }
          scopes.append(scope['key'])
        end

        site.data['schema'].each do |field|
          field_scope = field['field']['scope']
          next unless scopes.include?(field_scope)

          field_name = field['name']
          to_translate = field_name
          if field['field'].has_key?('translation_key')
            to_translate = field['field']['translation_key']
          elsif t[lang].has_key?('metadata_fields') && t[lang]['metadata_fields'].has_key?(field_name)
            to_translate = 'metadata_fields.' + field_name
          elsif field['field'].has_key?('label')
            to_translate = field['field']['label']
          end
          field_label = opensdg_translate_key(to_translate, t, lang)

          schema[field_scope]['properties'][field_name] = {
            "type" => "string",
            "format" => "markdown",
            "title" => field_label,
          }
        end

        # Regardless place the schema in site data so it can be used in Jekyll templates.
        site.data['schema-indicator-metadata'] = schema
      end
    end
  end
end
