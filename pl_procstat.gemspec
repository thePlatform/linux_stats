# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pl_procstat/version'

Gem::Specification.new do |spec|
  spec.name          = 'pl_procstat'
  spec.version       = PlProcstat::VERSION
  spec.authors       = ['Travis Bear']
  spec.email         = ['travis.bear@theplatform.com']
  spec.summary       = 'Lightweight OS stats extracted from /proc'
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ''
  spec.license       = 'thePlatform'

  spec.files         = Dir['lib/**/*.rb'] + Dir['README.md'] + Dir['docs/**/*'] - Dir['**/*~']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end