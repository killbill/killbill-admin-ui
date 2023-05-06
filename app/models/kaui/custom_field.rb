# frozen_string_literal: true

module Kaui
  class CustomField < KillBillClient::Model::CustomField
    def self.list_or_search(search_key = nil, offset = 0, limit = 10, options = {})
      if search_key.present?
        find_in_batches_by_search_key(search_key, offset, limit, options)
      else
        find_in_batches(offset, limit, options)
      end
    end
  end
end
