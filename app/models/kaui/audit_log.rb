class Kaui::AuditLog

  def self.description(log)
    if log.changed_by.present?
      changed_str = "Performed by #{log.changed_by} on #{ActionController::Base.helpers.format_date(log.change_date)}"
      if log.reason_code.blank? && log.comments.blank?
        changed_str
      elsif log.reason_code.blank?
        "#{changed_str}: #{log.comments}"
      else
        "#{changed_str} (#{log.reason_code} #{log.comments})"
      end
    end
  end
end
