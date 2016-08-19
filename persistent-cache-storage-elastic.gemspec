# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'persistent-cache/version'

Gem::Specification.new do |spec|
  spec.name          = "persistent-cache-storage-elastic"
  spec.version       = Persistent::Storage::Elastic::VERSION
  spec.authors       = ["Ernst Van Graan", "Olexij Tkatchenko"]
  spec.email         = ["ernst.van.graan@hetzner.co.za", "olexij.tkatchenko@advantest.com"]

  spec.summary       = %q{Provides a SQLite storage back-end to Persistent::Cache}
  spec.description   = %q{Provides a SQLite storage back-end to Persistent::Cache}
  spec.homepage      = "https://github.com/evangraan/persistent-cache-storage-elastic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'byebug'
  spec.add_dependency 'sqlite3', '1.3.10'
  spec.add_dependency "persistent-cache-storage-api"
  spec.add_dependency 'eh'
  spec.add_dependency "elasticsearch", "~> 1.0.13"
  spec.add_dependency "elasticsearch-api"
end