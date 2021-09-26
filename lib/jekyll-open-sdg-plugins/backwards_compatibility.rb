require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class BackwardsCompatibility < Jekyll::Generator
    safe true
    priority :low

    def add_translation_keys(statuses, site)
      statuses.each do |status|
        status_var = 'value'
        unless status.has_key?(status_var)
          status_var = 'status'
        end
        status_in_site_config = site.config['reporting_status']['status_types'].detect {|s| s['value'] == status[status_var] }
        if status_in_site_config.nil?
          opensdg_notice('Unexpected reporting status type: ' + status[status_var] + '. Expected reporting status types:')
          puts site.config['reporting_status']['status_types'].map { |s| s['value'] }
        end
        status['translation_key'] = status_in_site_config['label']
      end
    end

    # This file is used to avoid any backwards compatibility issues
    # as the Open SDG API changes over time.
    def generate(site)

      # Handle legacy treatment of reporting status types.
      unless (site.config.has_key?('reporting_status') &&
             site.config['reporting_status'].has_key?('status_types') &&
             site.config['reporting_status']['status_types'].count > 0)
        reporting_status = site.data['schema'].detect {|f| f['name'] == 'reporting_status' }
        reporting_status_types = reporting_status['field']['options']
        site.config['reporting_status']['status_types'] = reporting_status_types.map do |status_type|
          {
            'value' => status_type['value'],
            'label' => status_type['translation_key'],
          }
        end
      end

      # Also fill in the "reporting" data with things needed by older templates.
      add_translation_keys(site.data['reporting']['statuses'], site)
      add_translation_keys(site.data['reporting']['overall']['statuses'], site)

      if site.data['reporting'].has_key?('extra_fields')
        site.data['reporting']['extra_fields'].each do |key, extra_field|
          extra_field.each do |extra_field_value|
            add_translation_keys(extra_field_value['statuses'], site)
          end
        end
      end

      if site.data['reporting'].has_key?('goals')
        site.data['reporting']['goals'].each do |goal|
          add_translation_keys(goal['statuses'], site)
        end
      end

      puts site
    end
  end
end
