class Kaui::AuditLog < Kaui::Base
  define_attr :change_date
  define_attr :change_type
  define_attr :changed_by
  define_attr :comments
  define_attr :reason_code

  def initialize(data = {})
    super(:change_date => data['changeDate'],
          :change_type => data['changeType'],
          :changed_by => data['changedBy'],
          :comments => data['comments'],
          :reason_code => data['reasonCode'])
  end

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
