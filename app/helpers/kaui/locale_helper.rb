# frozen_string_literal: true

module Kaui
  module LocaleHelper
    def all_available_locales
      locale_yaml_file = File.join(File.dirname(__FILE__), 'locale_helper.yml')
      available_locales = YAML.load_file(locale_yaml_file)

      favorites = []
      locales = []

      available_locales.each do |locale|
        option = ["#{locale[:language]} #{locale[:country]} (#{locale[:language_tag]})", locale[:language_tag]]
        locales << option unless locale[:favorite]
        favorites << option if locale[:favorite]
      end

      favorites.push('---------------').concat(locales)
    end
  end
end
