# frozen_string_literal: true

# Hack for Zeitwerk
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
