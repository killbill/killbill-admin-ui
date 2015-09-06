module Kaui
  module UuidHelper

    def truncate_uuid(uuid)
      return uuid unless uuid =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
      split = uuid.split('-')
      split[0] + '-...-' + split[4]
    end
  end
end
