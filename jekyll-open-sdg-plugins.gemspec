lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-open-sdg-plugins/version"
Gem::Specification.new do |spec|
  spec.name          = "jekyll-open-sdg-plugins"
  spec.summary       = "Jekyll plugins for use with the Open SDG platform"
  spec.description   = "Jekyll plugins for use with the Open SDG platform"
  spec.version       = JekyllOpenSdgPlugins::VERSION
  spec.authors       = ["Brock Fanning"]
  spec.email         = ["brockfanning@gmail.com"]
  spec.homepage      = "https://github.com/open-sdg/jekyll-open-sdg-plugins"
  spec.licenses      = ["MIT"]
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|spec|features)/!)  }
  spec.require_paths = ["lib"]
  spec.add_dependency "jekyll", "~> 3.0"
  spec.add_dependency "deep_merge", "~> 1.2"
end
