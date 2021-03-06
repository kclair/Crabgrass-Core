# try loading rcov
begin
  require 'rcov/rcovtask'
rescue LoadError
  # STDERR.puts "rcov not installed"
  # ^^ I don't want to get this error every time.
end

# def plugins_with_allowed_fixtures
#   # skip plugins that load fixtures we don't have a schema for
#   Engines.plugins.by_precedence.reject do |p|
#      %w(
#      multiple_select
#      will_paginate
#      acts_as_versioned
#      acts_as_list
#      better_acts_as_tree
#      acts_as_state_machine
#      ).include? p.name
#   end
# end

#
# Faster tests
#
# Normally, "rake test:x" will invoke db:test:prepare. This is really slow.
# This is only needed when we have changed the database.
#
# The rake tasks listed here are copies of the ones in Rails, but with db:test:prepare removed.
#
namespace :test do
  namespace :fast do
    Rake::TestTask.new(:units) do |t|
      t.libs << "test"
      t.pattern = 'test/unit/**/*_test.rb'
      t.verbose = true
    end
    Rake::Task['test:fast:units'].comment = "Run test:units without db:test:prepare"

    Rake::TestTask.new(:functionals) do |t|
      t.libs << "test"
      t.pattern = 'test/functional/**/*_test.rb'
      t.verbose = true
    end
    Rake::Task['test:fast:functionals'].comment = "Run test:functionals without db:test:prepare"

    Rake::TestTask.new(:integration) do |t|
      t.libs << "test"
      t.pattern = 'test/integration/**/*_test.rb'
      t.verbose = true
    end
    Rake::Task['test:fast:integration'].comment = "Run test:integration without db:test:prepare"
  end
end

#
# Testing mods
#
namespace :test do
  namespace :mods do

    desc "Run the plugin tests in extensions/mods/**/test (or specify with MOD=name)"
    task :all => [:units, :functionals, :integration]

    desc "Run all plugin unit tests"
    Rake::TestTask.new(:units => :setup_plugin_fixtures) do |t|
      t.pattern = "extensions/mods/#{ENV['MOD'] || "**"}/test/unit/**/*_test.rb"
      t.verbose = true
    end

    desc "Run all plugin functional tests"
    Rake::TestTask.new(:functionals => :setup_plugin_fixtures) do |t|
      t.pattern = "extensions/mods/#{ENV['MOD'] || "**"}/test/functional/**/*_test.rb"
      t.verbose = true
    end

    desc "Integration test engines"
    Rake::TestTask.new(:integration => :setup_plugin_fixtures) do |t|
      t.pattern = "extensions/mods/#{ENV['MOD'] || "**"}/test/integration/**/*_test.rb"
      t.verbose = true
    end

    desc "Mirrors plugin fixtures into a single location to help plugin tests"
    task :setup_plugin_fixtures => :environment do
      if ENV['MOD']
        plugin = Engines.plugins.detect{|plugin|plugin.name == ENV['MOD']}
        unless plugin
          puts 'ERROR: mod plugin named "%s" not found.' % ENV['MOD']
          exit
        end
        Engines::Testing.setup_plugin_fixtures([plugin])
      else
        Engines::Testing.setup_plugin_fixtures
      end
    end

  end
end

#
# Testing pages
#
namespace :test do
  namespace :pages do

    desc "Run the plugin tests in extensions/pages/**/test (or specify with PAGE=name)"
    task :all => [:units, :functionals, :integration]

    desc "Run all pages unit tests"
    Rake::TestTask.new(:units => :setup_plugin_fixtures) do |t|
      t.pattern = "extensions/pages/#{ENV['PAGE'] || "**"}/test/unit/**/*_test.rb"
      t.verbose = true
    end

    desc "Run all pages functional tests"
    Rake::TestTask.new(:functionals => :setup_plugin_fixtures) do |t|
      t.pattern = "extensions/pages/#{ENV['PAGE'] || "**"}/test/functional/**/*_test.rb"
      t.verbose = true
    end

    desc "Integration test engines for pages"
    Rake::TestTask.new(:integration => :setup_plugin_fixtures) do |t|
      t.pattern = "extensions/pages/#{ENV['PAGE'] || "**"}/test/integration/**/*_test.rb"
      t.verbose = true
    end

    desc "Mirrors plugin fixtures into a single location to help plugin tests"
    task :setup_plugin_fixtures => :environment do
      # Engines::Testing.setup_plugin_fixtures
    end

  end
end

namespace :test do

  desc "Test everything: crabgrass, pages and mods."
  task :everything => "everything:default"

  task :coverage do
    Rake::Task["test:everything:with_rcov"].invoke
  end

  namespace :everything do
    desc "Test everything: crabgrass, pages and mods."
    task :default => :try_with_rcov

    def all_file_list
      # don't include mods by default
      list = FileList["test/**/*_test.rb"]
      list += FileList["extensions/pages/**/test/**/*_test.rb"]
      # FileList["mods/**/test/**/*_test.rb"]
      # find and add just the enabled  mods
      pwd = File.dirname(__FILE__)
      if conf = YAML.load_file(pwd + "/../../config/crabgrass/crabgrass.test.yml")
        mods = conf['enabled_mods'] || []
        mods.each { |m|
          list += FileList["mods/#{m}/test/**/*_test.rb"]
        }
      end

      return list
    end

    task :load_plugin_fixtures => [:environment, "db:test:prepare"] do
      # Engines::Testing.setup_plugin_fixtures(plugins_with_allowed_fixtures)
    end

    if defined? Rcov::RcovTask
      desc "Test everything and generate rcov statistics"
      Rcov::RcovTask.new(:with_rcov => :load_plugin_fixtures) do |t|
        t.libs << "test"

        t.test_files = all_file_list

        t.rcov_opts -= ["--text-report"]
        t.rcov_opts << "--rails"
        t.rcov_opts << "--text-summary"
        t.output_dir = "doc/coverage"

        if ENV["RCOV_NO_HTML"] == "true" or ENV["RCOV_NO_HTML"] == "1"
          t.rcov_opts << "--no-html"
        end

        t.rcov_opts << "-x ^/" # exclude all files with absolute path
        if ENV["RCOV_OPTS"]
          t.rcov_opts << ENV["RCOV_OPTS"]
        end
        t.verbose = true
      end
    end

    desc "Test everything without rcov"
    Rake::TestTask.new(:without_rcov => :load_plugin_fixtures) do |t|
      t.libs << "test"

      t.test_files = all_file_list
      t.verbose = true
    end

    desc "Try test everything with rcov if possible, fallback to everything without rcov"
    task :try_with_rcov do
      if defined? Rcov::RcovTask and ENV["NO_RCOV"] != "true"
        Rake::Task["test:everything:with_rcov"].invoke
      else
        Rake::Task["test:everything:without_rcov"].invoke
      end
    end

  end
end

