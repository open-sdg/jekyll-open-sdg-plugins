require "jekyll"
require_relative "helpers"

module Jekyll
  module TranslateMetadataField
    # Takes a metadata field (machine name) and returns a translated string
    # according to the language of the current page, suitable for displaying to
    # the public. It gets this string by looking in the site's "schema" for a
    # "translation_key" property, and running that through the
    # opensdg_translate_key() helper function.
    #
    # Temporary backwards compatibility: If the check fails, it falls back to
    # checking for a translation in the 'metadata_fields' translation group.
    #
    # More backwards compatibility: If all of the above fails, it falls back to
    # using whatever is in a "label" property in the schema.
    #
    # Parameters
    # ----------
    # field_name : string
    #   The machine name of a metadata field.
    def translate_metadata_field(field_name)

      # Determine the language of the current page.
      t = @context.registers[:site].data['translations']
      lang = @context.environments.first['page']['language']
      # Get the schema.
      schema = @context.registers[:site].data['schema']

      # Find the field.
      field = schema.select {|x| x['name'] == field_name }
      if field
        field = field.first()
      end

      to_translate = ''
      # First choice - use the 'translation_key' property from the schema.
      if field && field['field'].has_key?('translation_key')
        to_translate = field['field']['translation_key']
      # Next choice - try the 'metadata_fields' translation group.
      elsif t[lang].has_key?('metadata_fields') && t[lang]['metadata_fields'].has_key?(field_name)
        to_translate = 'metadata_fields.' + field_name
      # Next choice - use the 'label' from the schema.
      elsif field && field['field'].has_key?('label')
        to_translate = field['field']['label']
      # Last choice - just use the field name.
      else
        to_translate = field_name
      end

      return opensdg_translate_key(to_translate, t, lang)
    end
  end

  module TranslateMetadataFieldOption
    # Takes a metadata field (machine name) and option (value) and returns a
    # translated string according to the language of the current page, suitable
    # for displaying to the public.
    #
    # By contrast to TranslateMetadataField above, this is for translating the
    # options of multiple-choice schema fields. But similar to
    # TranslateMetadataField, this looks for a "translation_key" property on
    # the option in the schema.
    #
    # Temporary backwards compatibility: If the check fails, it falls back to
    # whatever is in a "name" property in the schema.
    #
    # Parameters
    # ----------
    # field_name : string
    #   The machine name of a metadata field.
    # value : string
    #   The 'value' of the option to use.
    def translate_metadata_field_option(field_name, value)

      # Determine the language of the current page.
      t = @context.registers[:site].data['translations']
      lang = @context.environments.first['page']['language']
      # Get the schema.
      schema = @context.registers[:site].data['schema']

      # Find the field.
      field = schema.select {|x| x['name'] == field_name}
      if field
        field = field.first()
      end

      # Fall back to the value itself.
      to_translate = value

      # Look for the 'translation_key' property from the schema.
      if field && field['field'].has_key?('options')
        option = field['field']['options'].select {|x| x['value'] == value}
        if option
          option = option.first()
          if option.has_key?('translation_key')
            to_translate = option['translation_key']
          else
            to_translate = option['name']
          end
        end
      end

      return opensdg_translate_key(to_translate, t, lang)

    end
  end
end

Liquid::Template.register_filter(Jekyll::TranslateMetadataField)
Liquid::Template.register_filter(Jekyll::TranslateMetadataFieldOption)
