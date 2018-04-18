class Kaui::AuditLogsController < Kaui::EngineController

  def index
    cached_options_for_klient = options_for_klient
    account = Kaui::Account::find_by_id_or_key(params.require(:account_id), false, false, cached_options_for_klient)
    audit_logs = account.audit(cached_options_for_klient)


    formatter = lambda do |log|
      [
          log.change_date,
          view_context.content_tag(:span, view_context.truncate_uuid(log.object_id), title: log.object_id ),
          log.object_type,
          log.change_type,
          log.changed_by,
          log.reason_code,
          log.comments,
          view_context.content_tag(:span, view_context.truncate_uuid(log.user_token), title: log.user_token )
      ]
    end

    @audit_logs_json = []
    audit_logs.each { |page| @audit_logs_json << formatter.call(page) }

    @audit_logs_json = @audit_logs_json.to_json
  end

end