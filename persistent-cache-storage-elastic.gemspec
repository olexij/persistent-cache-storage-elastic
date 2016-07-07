# coding: utf-8


lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'persistent-cache/version'

Gem::Specification.new do |spec|
  spec.name          = "persistent-cache-storage-elastic"
  spec.version       = Persistent::Storage::Elastic::VERSION
  spec.authors       = ["Ernst Van Graan"]
  spec.email         = ["ernst.van.graan@hetzner.co.za"]

  spec.summary       = %q{Provides an elastic search storage back-end to Persistent::Cache}
  spec.description   = %q{Provides an elastic search storage back-end to Persistent::Cache}
  spec.homepage      = "https://github.com/evangraan/persistent-cache-storage-elastic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "eh"
  spec.add_dependency "persistent-cache-storage-api"
end
