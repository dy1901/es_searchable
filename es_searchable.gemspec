# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'es_searchable/version'

Gem::Specification.new do |spec|
  spec.name          = "es_searchable"
  spec.version       = EsSearchable::VERSION
  spec.authors       = ["zuozuo"]
  spec.email         = ["c_yzuo@groupon.com"]
  spec.summary       = %q{A small wrapper of elasticsearch search api}
  spec.description   = %q{A small wrapper of elasticsearch search api}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.6"
	spec.add_dependency "rake"
	spec.add_dependency "awesome_print"
	spec.add_dependency "elasticsearch"
	spec.add_dependency "elasticsearch-rails", "~> 0.1.7"
	spec.add_dependency "elasticsearch-model", "~> 0.1.8"
	spec.add_dependency "sidekiq"
  spec.add_development_dependency "sqlite3"
end
