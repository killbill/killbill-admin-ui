require 'active_model'

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

  def description
    if changed_by.present?
      changed_str = "Performed by #{changed_by} on #{ActionController::Base.helpers.format_date(change_date)}"
      if reason_code.blank? && comments.blank?
        changed_str
      elsif reason_code.blank?
        "#{changed_str}: #{comments}"
      else
        "#{changed_str} (#{reason_code} #{comments})"
      end
    end
  end
end
