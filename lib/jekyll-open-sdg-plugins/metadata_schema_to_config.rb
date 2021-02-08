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

      if form_config
        metadata_form_config = form_config['indicator_metadata']
        scopes = ['national', 'global']
        if metadata_form_config && metadata_form_config.has_key?('scopes')
          if metadata_form_config['scopes'].kind_of?(Array) && metadata_form_config['scopes'].length() > 0
            scopes = metadata_form_config['scopes']
          end
        end

        schema = {
          "type" => "object",
          "title" => "Edit Metadata",
          "properties" => {},
        }

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

          schema['properties'][field_name] = {
            "type" => "string",
            "format" => "markdown",
            "title" => field_label,
          }
          schema['additionalProperties'] = true
        end

        # Regardless place the schema in site data so it can be used in Jekyll templates.
        site.data['schema-indicator-metadata'] = schema
      end
    end
  end
end
