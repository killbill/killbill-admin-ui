# frozen_string_literal: true

module Kaui
  module RailsMethods
    def self.included(base_class)
      base_class.class_eval do
        # Required to build urls in views
        extend  ActiveModel::Naming
        include ActiveModel::Validations
        # Required to make form_for work
        include ActiveModel::Conversion

        def ==(other)
          !other.nil? && self.class == other.class && to_hash == other.to_hash
        end

        def persisted?
          # Hard to know...
          false
        end

        def new_record?
          !persisted?
        end

        def to_param
          # Hard to know (depends on the model)...
          nil
        end

        def read_attribute_for_validation(attr)
          send(attr)
        end

        def save
          @errors.add(:save, 'Saving this object is not yet supported')
          false
        end

        def update_attributes(_tag_definition)
          @errors.add(:update, 'Updating this object is not yet supported')
          false
        end

        def destroy
          @errors.add(:destroy, 'Destroying this object is not yet supported')
          false
        end
      end

      base_class.instance_eval do
        def self.human_attribute_name(attr, _options = {})
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

        def self.find(_id)
          nil
        end
      end
    end
  end
end
