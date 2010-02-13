# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{officer}
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chad Remesch"]
  s.date = %q{2010-02-13}
  s.default_executable = %q{officer}
  s.description = %q{Distributed lock server and client written in Ruby and EventMachine}
  s.email = %q{chad@remesch.com}
  s.executables = ["officer"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "bin/officer",
     "lib/officer.rb",
     "lib/officer/client.rb",
     "lib/officer/commands.rb",
     "lib/officer/connection.rb",
     "lib/officer/lock_store.rb",
     "lib/officer/log.rb",
     "lib/officer/server.rb",
     "officer.gemspec",
     "test/helper.rb",
     "test/test_officer.rb"
  ]
  s.homepage = %q{http://github.com/chadrem/officer}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Distributed lock server and client}
  s.test_files = [
    "test/helper.rb",
     "test/test_officer.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<eventmachine>, [">= 0"])
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<daemons>, [">= 0"])
      s.add_development_dependency(%q<choice>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<daemons>, [">= 0"])
      s.add_dependency(%q<choice>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<daemons>, [">= 0"])
    s.add_dependency(%q<choice>, [">= 0"])
  end
end

