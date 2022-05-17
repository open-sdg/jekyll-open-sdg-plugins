require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class SiteConfiguration < Jekyll::Generator
    safe true
    priority :highest

    # This looks for site configuration in the data directory, and if found, copies it to
    # the "site" object, as if it had been in _config.yml. It looks in "site_config" for
    # configuration to move. In addition, if jekyll.environment or site.environment is
    # specifically "production", then it also moves data from "site_config_prod".
    #
    # This allows you to keep all OpenSDG-specific config out of _config.yml, and instead
    # place it in site_config and/or site_config_prod in your data directory.
    def generate(site)

      if site.data.has_key?('site_config')
        hash_to_hash(site.data['site_config'], site.config)
      end

      production = false
      if Jekyll.env == 'production'
        production = true
      end
      if site.config.has_key?('environment') && site.config['environment'] == 'production'
        production = true
      end

      if production && site.data.has_key?('site_config_prod')
        hash_to_hash(site.data['site_config_prod'], site.config)
      end

      # Look for environment variables for some settings.
      env_settings = [
        'REPOSITORY_URL_SITE',
      ]
      env_settings.each do |setting|
          if ENV.has_key?(setting)
            site.config[setting.downcase] = ENV[setting]
          end
      end

      # Abort early if some required settings are not there.
      unless site.config.has_key?('languages') && site.config['languages'].length > 0
        opensdg_error('The "languages" site configuration must have at least one language. See the documentation here: https://open-sdg.readthedocs.io/en/latest/configuration/#languages')
      end

      # Hardcode some variables.
      site.config['disaggregation_status'] = {}
      site.config['disaggregation_status']['status_types'] = [
        {
          'value' => 'complete',
          'label' => 'status.disaggregation_status_complete',
        },
        {
          'value' => 'inprogress',
          'label' => 'status.disaggregation_status_inprogress',
        },
        {
          'value' => 'notstarted',
          'label' => 'status.disaggregation_status_notstarted',
        },
        {
          'value' => 'notapplicable',
          'label' => 'status.disaggregation_status_notapplicable',
        },
      ]

      # Provide some defaults.
      if !site.config.has_key?('time_series_attributes') or site.config['time_series_attributes'].length == 0
        site.config['time_series_attributes'] = [
          {
            'field' => 'COMMENT_TS',
            'label' => 'indicator.footnote',
          },
          {
            'field' => 'DATA_LAST_UPDATE',
            'label' => 'metadata_fields.national_data_update_url'
          },
        ]
      end
    end

    # Copy properties from a hash onto another hash.
    def hash_to_hash(hash_from, hash_to)
      hash_from.each do |key, value|
        hash_to[key] = value
      end
    end
  end
end
