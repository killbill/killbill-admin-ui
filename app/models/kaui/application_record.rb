# frozen_string_literal: true

module Kaui
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
