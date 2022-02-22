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
        unless site.config.has_key?('reporting_status')
          site.config['reporting_status'] = {}
        end
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

      # Print warnings for settings that are deprecated
      # and will be removed in version 2.0.0.
      there_was_a_deprecation_notice = false
      if !site.config.has_key?('accessible_charts') || !site.config['accessible_charts']
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the accessible_charts setting will be automatically set to true.')
      end
      if !site.config.has_key?('accessible_tabs') || !site.config['accessible_tabs']
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the accessible_tabs setting will be automatically set to true.')
      end
      if !site.config.has_key?('contrast_type') || site.config['contrast_type'] != 'single'
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the contrast_type setting will be automatically set to "single".')
      end
      if site.config.has_key?('create_goals') && site.config['create_goals']['layout'] != 'goal-with-progress'
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the create_goals.layout setting will be automatically set to "goal-with-progress".')
      end
      if site.config.has_key?('create_pages')
        site.config['create_pages'].each do |page|
          if page['layout'] == 'frontpage'
            opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the "frontpage" layout will become the same as the "frontpage-alt" layout.')
            there_was_a_deprecation_notice = true
          end
        end
      end
      if !site.config.has_key?('favicons') || site.config['favicons'] != 'favicon.io'
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the favicons setting will be automatically set to "favicon.io".')
      end
      if site.config.has_key?('frontpage_heading') && site.config['frontpage_heading'] != ''
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the "frontpage_heading" setting will no longer be used.')
      end
      if site.config.has_key?('frontpage_instructions') && site.config['frontpage_instructions'] != ''
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the "frontpage_instructions" setting will no longer be used.')
      end
      if site.config.has_key?('header') && site.config['header']['include'] != 'header-menu-left-aligned.html'
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the "header.include" setting will automatically be set to "header-menu-left-aligned.html".'
      end
      if site.config.has_key?('non_global_metadata') && site.config['non_global_metadata'] != ''
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the "non_global_metadata" setting will be removed. Please use the "metadata_tabs" setting to control the labels of the metadata tabs.'
      end
      if !site.config.has_key?('series_toggle') || !site.config['series_toggle']
        there_was_a_deprecation_notice = true
        opensdg_notice('DEPRECATION NOTICE: In Open SDG 2.0.0, the "series_toggle" will be automatically set to "true".')
      end
    end
  end
end
