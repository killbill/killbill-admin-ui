# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren, Style/OneClassPerFile

# Hack for Zeitwerk - must define Kaui::KillbillRegisterable before Devise::Models::KillbillRegisterable
module Kaui
  module KillbillRegisterable; end
end

module Devise
  module Models
    module KillbillRegisterable
      include Registerable
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren, Style/OneClassPerFile
