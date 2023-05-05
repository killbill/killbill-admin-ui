# Hack for Zeitwerk
module Kaui::KillbillRegisterable; end

module Devise
  module Models
    module KillbillRegisterable
      include Registerable
    end
  end
end
