# -*- encoding: utf-8 -*-
require File.expand_path('../lib/officer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Chad Remesch']
  gem.email         = ['chad@remesch.com']
  gem.description   = 'Officer is designed to help you coordinate distributed processes and avoid race conditions.'
  gem.summary       = 'Ruby lock server and client built on EventMachine.'
  gem.homepage      = 'http://github.com/chadrem/officer'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'officer'
  gem.require_paths = ['lib']
  gem.version       = Officer::VERSION

  gem.add_dependency('eventmachine', ['>= 0'])
  gem.add_dependency('json', ['>= 0'])
  gem.add_dependency('daemons', ['>= 0'])
  gem.add_dependency('choice', ['>= 0'])

  gem.add_development_dependency('rake', ['>= 0'])
  gem.add_development_dependency('rspec', ['>= 0'])
end
