# frozen_string_literal: true

require 'rbconfig'
require 'active_support/core_ext/string'
require 'thor'
require 'thor/group'
require 'kaui/version'

module KauiCmd
  class Installer < Thor::Group
    include Thor::Actions

    desc 'Install Kaui inside an existing rails project'

    argument :app_path, type: :string, desc: 'rails app_path', default: '.'

    class_option :version, type: :string, desc: 'Kaui Version to use'

    class_option :edge, type: :boolean

    class_option :path, type: :string, desc: 'Kaui gem path'
    class_option :git, type: :string, desc: 'Kaui gem git url'
    class_option :ref, type: :string, desc: 'Kaui gem git ref'
    class_option :branch, type: :string, desc: 'Kaui gem git branch'
    class_option :tag, type: :string, desc: 'Kaui gem git tag'

    class_option :skip_bundle, type: :boolean, desc: "Don't run bundle install"

    def verify_rails
      return if rails_project?

      say "#{@app_path} is not a rails project."
      exit 1
    end

    def prepare_options
      @kaui_gem_options = {}

      if options[:edge]
        @kaui_gem_options[:git] = 'git://github.com/killbill/killbill-admin-ui.git'
      elsif options[:path]
        @kaui_gem_options[:path] = options[:path]
      elsif options[:git]
        @kaui_gem_options[:git] = options[:git]
        @kaui_gem_options[:ref] = options[:ref] if options[:ref]
        @kaui_gem_options[:branch] = options[:branch] if options[:branch]
        @kaui_gem_options[:tag] = options[:tag] if options[:tag]
      elsif options[:version]
        @kaui_gem_options[:version] = options[:version]
      else
        version = Kaui::VERSION
        @kaui_gem_options[:version] = version.to_s
      end
    end

    def add_gems
      inside @app_path do
        gem :kaui, @kaui_gem_options
        run 'bundle install', capture: true unless options[:skip_bundle]
      end
    end

    def initialize_kaui
      inside @app_path do
        run 'rails generate kaui:install', verbose: false
      end
    end

    private

    def rails_project?
      File.exist?(File.join(@app_path, 'script', 'rails')) || File.exist?(File.join(@app_path, 'bin', 'rails'))
    end

    def gem(name, gem_options = {})
      say_status :gemfile, name
      parts = ["'#{name}'"]
      parts << ["'#{gem_options.delete(:version)}'"] if gem_options[:version]
      gem_options.each { |key, value| parts << ":#{key} => '#{value}'" }
      append_file 'Gemfile', "gem #{parts.join(', ')}\n", verbose: false
    end
  end
end
