module Kaui
  module UuidHelper

    def truncate_uuid(uuid)
      return uuid unless uuid =~ /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
      split = uuid.split('-')
      split[0] + '-...-' + split[4]
    end

    def object_id_popover(object_id, placement = 'right', title = nil)
      content_tag(:span, truncate_uuid(object_id),
                  id: "#{object_id}-popover", class: 'object-id-popover', title: title,
                  data: {
                      id: object_id,
                      placement: placement,
                  } )
    end
  end
end
