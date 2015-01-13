module Kaui
  module UuidHelper

    def truncate_uuid(uuid)
      split = uuid.split('-')
      split[0] + '-...-' + split[4]
    end
  end
end
