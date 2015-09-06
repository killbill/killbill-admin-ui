class Kaui::AuditLog

  def self.description(log)
    if log.changed_by.present?
      changed_str = "Done by #{log.changed_by.strip} on #{ActionController::Base.helpers.format_date(log.change_date)}"
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
