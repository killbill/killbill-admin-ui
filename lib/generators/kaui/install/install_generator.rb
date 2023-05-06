# frozen_string_literal: true

require 'rails/generators'
require 'kaui/version'

module Kaui
  class InstallGenerator < Rails::Generators::Base
    class_option :lib_name, type: :string, default: 'kaui'

    def self.source_paths
      paths = superclass.source_paths
      paths << File.expand_path('../templates', "../../#{__FILE__}")
      paths << File.expand_path('../templates', "../#{__FILE__}")
      paths << File.expand_path('templates', __dir__)
      paths.flatten
    end

    def add_files
      template 'config/initializers/kaui.rb', 'config/initializers/kaui.rb'
    end

    def config_kaui_yml
      create_file 'config/kaui.yml' do
        settings = { 'version' => Kaui::VERSION }

        settings.to_yaml
      end
    end

    def additional_tweaks
      return unless File.exist? 'public/robots.txt'

      append_file 'public/robots.txt', <<~ROBOTS
        User-agent: *
        Disallow: /kaui
      ROBOTS
    end

    def setup_assets
      @lib_name = 'kaui'
      %w[javascripts stylesheets images].each do |path|
        empty_directory "app/assets/#{path}/kaui"
      end

      template 'app/assets/javascripts/kaui/all.js'
      template 'app/assets/stylesheets/kaui/all.css'
    end

    def update_routes
      insert_into_file File.join('config', 'routes.rb'), after: "Application.routes.draw do\n" do
        %(
  # This line mounts Kaui's routes at the root of your application.
  # If you're mounting this engine into an existing application, change it to e.g.
  # mount Kaui::Engine, :at => '/kaui', :as => "kaui_engine"
  #
  # Don't modify the :as => "kaui_engine" option though.
  mount Kaui::Engine, :at => '/', :as => "kaui_engine"
        )
      end
    end

    def complete
      return if options[:quiet]

      puts '*' * 50
      puts "Kaui has been installed successfully. You're all ready to go!"
      puts ' '
      puts 'Enjoy!'
    end
  end
end
