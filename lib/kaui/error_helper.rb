require 'rest_client'

module Kaui
  module ErrorHelper
    def as_string(e)
      if e.is_a?(RestClient::Exception)
        "#{e.message} #{e.response}".split(/\n/).take(5).join("\n")
      elsif e.is_a?(KillBillClient::API::ResponseError)
        "Error #{e.response.code}: #{e.response.message}"
      else
        e.message
      end
    end
  end
end
