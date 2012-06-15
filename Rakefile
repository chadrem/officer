require 'rubygems'
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "officer"
  gem.homepage = "http://github.com/chadrem/officer"
  gem.license = "MIT"
  gem.summary = %Q{Ruby lock server and client built on EventMachine.}
  gem.description = %Q{Officer is designed to help you coordinate distributed processes and avoid race conditions.}
  gem.email = "chad@remesch.com"
  gem.authors = ["Chad Remesch"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  # gem.add_development_dependency 'rspec', '2.4.0'
  gem.add_dependency "eventmachine", ">= 0"
  gem.add_dependency "json", ">= 0"
  gem.add_dependency "daemons", ">= 0"
  gem.add_dependency "choice", ">= 0"

end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'officer'
