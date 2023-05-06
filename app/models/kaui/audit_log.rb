# frozen_string_literal: true

module Kaui
  class AuditLog
    def self.description(log)
      return unless log.changed_by.present?

      changed_str = "#{log.change_type} by #{log.changed_by.strip}"
      if log.reason_code.blank? && log.comments.blank?
        changed_str
      elsif log.reason_code.blank?
        "#{changed_str}: #{log.comments.strip}"
      elsif log.comments.blank?
        "#{changed_str}: #{log.reason_code.strip}"
      else
        "#{changed_str} (#{log.reason_code.strip} #{log.comments.strip})"
      end
    end
  end
end
