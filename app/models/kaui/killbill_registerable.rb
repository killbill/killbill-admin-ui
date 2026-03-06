# frozen_string_literal: true

# Hack for Zeitwerk
# rubocop:disable Style/OneClassPerFile
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
# rubocop:enable Style/OneClassPerFile
