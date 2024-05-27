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
      form_settings = site.config['indicator_metadata_form']
      t = site.data['translations']
      lang = language_config[0]

      if form_settings && form_settings['enabled']
        scopes = ['national', 'global']
        if form_settings && form_settings.has_key?('scopes')
          if form_settings['scopes'].kind_of?(Array) && form_settings['scopes'].length() > 0
            scopes = form_settings['scopes']
          end
        end
        exclude_fields = []
        if form_settings && form_settings.has_key?('exclude_fields')
          if form_settings['exclude_fields'].kind_of?(Array) && form_settings['exclude_fields'].length() > 0
            exclude_fields = form_settings['exclude_fields']
          end
        end
        if form_settings && form_settings.has_key?('language') && form_settings['language'] != ''
          lang = form_settings['language']
        end

        schema = {
          "type" => "object",
          "title" => opensdg_translate_key('indicator.edit_metadata', t, lang),
          "properties" => {},
        }

        site.data['schema'].each do |field|
          field_name = field['name']
          field_scope = field['field']['scope']
          next unless scopes.include?(field_scope)
          next if exclude_fields.include?(field_name)

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
            "description" => 'Scope: ' + field_scope + ', Field: ' + field_name,
          }
          schema['additionalProperties'] = true
        end
      end
    end
  end
end
