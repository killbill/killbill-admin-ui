# frozen_string_literal: true

module Kaui
  module ApplicationHelper
    def tenant_selected?
      session[:kb_tenant_id].present?
    end

    def truncate_class_name(klass, with_abbr)
      splitted = klass.split('.')
      if with_abbr
        splitted.each_with_index.map { |k, idx| idx == splitted.size - 1 ? k : "#{k[0]}." }.join
      else
        splitted[-1]
      end
    end
  end
end
