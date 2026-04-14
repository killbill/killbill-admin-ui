#!/usr/bin/env rake

# Install tasks to build and release the plugin
require 'bundler/setup'
Bundler::GemHelper.install_tasks

# Install test tasks
require 'rspec/core/rake_task'
namespace :test do
  desc 'Run RSpec tests'
  RSpec::Core::RakeTask.new do |task|
    task.name = 'spec'
    task.pattern = './spec/*/*_spec.rb'
  end

  namespace :remote do
    desc 'Run RSpec remote tests'
    RSpec::Core::RakeTask.new do |task|
      task.name = 'spec'
      task.pattern = './spec/*/remote/*_spec.rb'
    end
  end
end

# Run tests by default
task :default => 'test:spec'
