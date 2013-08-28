module Kaui
  module RailsMethods
    
    # let all the rails mocks be here
    def self.included(base_class)
      base_class.class_eval do
        extend  ActiveModel::Naming
        include ActiveModel::Validations
        include ActiveModel::Conversion
      end
    end

    def ==(other)
      !other.nil? && self.class == other.class && self.to_hash == other.to_hash
    end

    def persisted?
      @persisted
    end

    def new_record?
      !persisted?
    end

    def to_param
      # id is a string (killbill UUID)
      @id
    end

    def read_attribute_for_validation(attr)
      send(attr)
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    def self.all
      []
    end

    def self.count
      all.count
    end

    def self.find(id)
      nil
    end

    def save
      @errors.add(:save, 'Saving this object is not yet supported')
      false
    end

    def update_attributes(tag_definition)
      @errors.add(:update, 'Updating this object is not yet supported')
      false
    end

    def destroy
      @errors.add(:destroy, 'Destroying this object is not yet supported')
      false
    end

  end
end
