class Kaui::AuditLogsController < Kaui::EngineController
  OBJECT_WITH_HISTORY = %w[ACCOUNT ACCOUNT_EMAIL CUSTOM_FIELD PAYMENT_ATTEMPTS PAYMENTS PAYMENT_METHODS PAYMENT_TRANSACTIONS REFUNDS TAG_DEFINITIONS TAG]

  def index
    cached_options_for_klient = options_for_klient
    @account = Kaui::Account::find_by_id_or_key(params.require(:account_id), false, false, cached_options_for_klient)
    audit_logs = @account.audit(cached_options_for_klient)


    formatter = lambda do |log|
      object_id_text = view_context.content_tag(:span, view_context.truncate_uuid(log.object_id), title: log.object_id )
      if object_with_history?(log.object_type)
        object_id_text = view_context.link_to(object_id_text, '#showHistoryModal',
                                              data: {
                                                  toggle: 'modal',
                                                  object_id: log.object_id,
                                                  object_type: log.object_type,
                                                  change_date: log.change_date,
                                                  account_id: @account.account_id
                                              })
      end

      [
          log.change_date,
          object_id_text,
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

  def history
    json_response do
      object_id = params.require(:object_id)
      object_type = params.require(:object_type)
      cached_options_for_klient = options_for_klient

      audit_logs_with_history = []
      error = nil

      begin
        if object_type == 'ACCOUNT'
          account = Kaui::Account::find_by_id_or_key(object_id, false, false, cached_options_for_klient)
          audit_logs_with_history = account.audit_logs_with_history(cached_options_for_klient)
        else
          error = "Object [#{object_type}] history is not supported."
        end

      rescue Exception => e
        error = e.message
      end

      { audits: audit_logs_with_history, error: error }
    end
  end

  private

    def object_with_history?(object_type)
      return false if object_type.nil?
      OBJECT_WITH_HISTORY.include?(object_type)
    end

end