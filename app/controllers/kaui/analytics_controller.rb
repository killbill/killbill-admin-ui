module Kaui
  class AnalyticsController < ApplicationController
    def index
    end

    def accounts_over_time
      @accounts = Analytics.accounts_over_time
    end
  end
end