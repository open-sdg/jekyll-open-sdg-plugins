require "jekyll"
require_relative "helpers"

module JekyllOpenSdgPlugins
  class BackwardsCompatibility < Jekyll::Generator
    safe true
    priority :low

    # This file is used to avoid any backwards compatibility issues
    # as the Open SDG API changes over time.
    def generate(site)

        # Handle legacy treatment of reporting status types.
        unless site.config.has_key?('reporting_status') &&
               site.config['reporting_status'].has_key?('status_types') &&
               site.config['reporting_status']['status_types'].count > 0
            puts "Foo"
        endunless

    end
  end
end
