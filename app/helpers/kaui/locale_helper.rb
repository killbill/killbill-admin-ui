module Kaui
  module LocaleHelper

    def get_available_locales
      locale_yaml_file = File.join(File.dirname(__FILE__), 'locale_helper.yml')
      available_locales = YAML::load_file(locale_yaml_file)

      favorites = []
      locales = []

      available_locales.each do |locale|
        option = ["#{locale[:language]} #{locale[:country]} (#{locale[:language_tag]})", locale[:language_tag] ]
        locales << option
        favorites << option if locale[:favorite]
      end

      favorites.concat(['---------------']).concat(locales)
    end
  end
end