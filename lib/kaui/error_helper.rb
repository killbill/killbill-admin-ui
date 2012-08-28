require 'rest_client'

module Kaui
  module ErrorHelper
    def as_string(e)
      if e.is_a?(RestClient::Exception)
        "#{e.message} #{e.response}".split(/\n/).take(5).join("\n")
      else
        e.message
      end
    end
  end
end
