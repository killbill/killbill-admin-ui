#!/usr/bin/env rake
# frozen_string_literal: true

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

APP_RAKEFILE = File.expand_path('test/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

namespace :test do
  desc 'Runs all the unit tests'
  Rake::TestTask.new(:units) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/unit/**/*_test.rb'
    t.verbose = false
  end
end

task default: :test
