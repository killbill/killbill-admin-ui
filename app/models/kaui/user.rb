module Kaui
  class User < ActiveRecord::Base
    devise :killbill_authenticatable
  end
end
