module KillBillClient
  module Model
    class Account < AccountAttributes

      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      has_custom_fields KILLBILL_API_ACCOUNTS_PREFIX, :account_id
      has_tags KILLBILL_API_ACCOUNTS_PREFIX, :account_id
      has_audit_logs_with_history KILLBILL_API_ACCOUNTS_PREFIX, :account_id

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_in_batches(offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset                   => offset,
                  :limit                    => limit,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_external_key(external_key, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}",
              {
                  :externalKey              => external_key,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/search/#{search_key}",
              {
                  :offset                   => offset,
                  :limit                    => limit,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_children(account_id, with_balance = false, with_balance_and_cba = false, audit='NONE', options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/children",
              {
                :audit                    => audit,
                :accountWithBalance       => with_balance,
                :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def blocking_state_audit_logs_with_history(blocking_state_id, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/block/#{blocking_state_id}/auditLogsWithHistory",
              {},
              options,
              AuditLog
        end

        def paginated_bundles(account_id, offset = 0, limit = 100, audit = "NONE", options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles/pagination",
                          {
                            :offset => offset,
                            :limit => limit,
                            :audit => audit
                          },
                          options,
                          Bundle
        end

        def paginated_invoices(account_id, offset = 0, limit = 100, audit = "NONE", options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoices/pagination",
                   {
                    :offset => offset,
                    :limit => limit,
                    :audit => audit
                   },
                   options,
                   Invoice
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_account = self.class.post KILLBILL_API_ACCOUNTS_PREFIX,
                                          to_json,
                                          {},
                                          {
                                              :user    => user,
                                              :reason  => reason,
                                              :comment => comment,
                                          }.merge(options)
        created_account.refresh(options)
      end

      def update(treat_null_as_reset = false, user = nil, reason = nil, comment = nil, options = {})

        params = {}
        params[:treatNullAsReset] = treat_null_as_reset

        self.class.put "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
                       to_json,
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)

        self.class.find_by_id(account_id, nil, nil, options)

      end


      def close(cancel_subscriptions, writeoff_unpaid_invoices,  item_adjust_unpaid_invoices, user = nil, reason = nil, comment = nil, options = {})
        created_account = self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
                                            {},
                                            {
                                                :cancelAllSubscriptions => cancel_subscriptions,
                                                :writeOffUnpaidInvoices => writeoff_unpaid_invoices,
                                                :itemAdjustUnpaidInvoices => item_adjust_unpaid_invoices
                                            },
                                            {
                                                :user    => user,
                                                :reason  => reason,
                                                :comment => comment,
                                            }.merge(options)
        created_account.refresh(options)
      end



      def transfer_child_credit(user = nil, reason = nil, comment = nil, options = {})
        self.class.put "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/transferCredit",
                        {},
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end


      def bundles(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles",
                       {},
                       options,
                       Bundle
      end

      def invoices(options = {})
        params_hash = options.delete(:params)
        options_to_merge = params_hash.nil? ? {} : params_hash
        merged_options = { :includeInvoiceComponents => true }.merge(options_to_merge)
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoices",
                 merged_options,
                 options,
                 Invoice
      end

      def migration_invoices(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoices",
                       {
                           :withMigrationInvoices => true
                       },
                       options,
                       Invoice
      end

      def payments(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       options,
                       Payment
      end

      def overdue(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/overdue",
                       {},
                       options,
                       OverdueStateAttributes
      end

      def children(with_balance = false, with_balance_and_cba = false, audit='NONE', options = {})
        Account::find_children(self.account_id, with_balance, with_balance_and_cba, audit, options)
      end

      def auto_pay_off?(options = {})
        control_tag?(AUTO_PAY_OFF_ID, options)
      end

      def set_auto_pay_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(AUTO_PAY_OFF_ID, user, reason, comment, options)
      end

      def remove_auto_pay_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(AUTO_PAY_OFF_ID, user, reason, comment, options)
      end

      def auto_invoicing_off?(options = {})
        control_tag?(AUTO_INVOICING_OFF_ID, options)
      end

      def set_auto_invoicing_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(AUTO_INVOICING_OFF_ID, user, reason, comment, options)
      end

      def remove_auto_invoicing_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(AUTO_INVOICING_OFF_ID, user, reason, comment, options)
      end

      def overdue_enforcement_off?(options = {})
        control_tag?(OVERDUE_ENFORCEMENT_OFF_ID, options)
      end

      def set_overdue_enforcement_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(OVERDUE_ENFORCEMENT_OFF_ID, user, reason, comment, options)
      end

      def remove_overdue_enforcement_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(OVERDUE_ENFORCEMENT_OFF_ID, user, reason, comment, options)
      end

      def written_off?(options = {})
        control_tag?(WRITTEN_OFF_ID, options)
      end

      def set_written_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(WRITTEN_OFF_ID, user, reason, comment, options)
      end

      def remove_written_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(WRITTEN_OFF_ID, user, reason, comment, options)
      end

      def manual_pay?(options = {})
        control_tag?(MANUAL_PAY_ID, options)
      end

      def set_manual_pay(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(MANUAL_PAY_ID, user, reason, comment, options)
      end

      def remove_manual_pay(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(MANUAL_PAY_ID, user, reason, comment, options)
      end

      def test?(options = {})
        control_tag?(TEST_ID, options)
      end

      def set_test(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(TEST_ID, user, reason, comment, options)
      end

      def remove_test(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(TEST_ID, user, reason, comment, options)
      end

      def add_email(email, user = nil, reason = nil, comment = nil, options = {})
        self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails",
                        {
                            # TODO Required ATM
                            :accountId => account_id,
                            :email     => email
                        }.to_json,
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end

      def remove_email(email, user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails/#{email}",
                          {},
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def emails(audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails",
                       {
                           :audit => audit
                       },
                       options,
                       AccountEmailAttributes
      end

      def email_audit_logs_with_history(account_email_id, options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails/#{account_email_id}/auditLogsWithHistory",
                       {},
                       options,
                       AuditLog
      end

      def all_tags(object_type, included_deleted, audit = 'NONE', options = {})
        params = {}
        params[:objectType] = object_type if object_type
        params[:includedDeleted] = included_deleted if included_deleted
        params[:audit] = audit
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/allTags",
                       params,
                       options,
                       Tag
      end

      def all_custom_fields(object_type, audit = 'NONE', options = {})
        params = {}
        params[:objectType] = object_type if object_type
        params[:audit] = audit
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/allCustomFields",
                       params,
                       options,
                       CustomField
      end

      def blocking_states(blocking_state_types, blocking_state_svcs, audit = 'NONE', options = {})
        params = {}
        params[:blockingStateTypes] = blocking_state_types if blocking_state_types
        params[:blockingStateSvcs] = blocking_state_svcs if blocking_state_svcs
        params[:audit] = audit
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/block",
                       params,
                       options,
                       BlockingStateAttributes

      end

      def set_blocking_state(state_name, service, is_block_change, is_block_entitlement, is_block_billing, requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        params = {}
        params[:requestedDate] = requested_date if requested_date

        body = KillBillClient::Model::BlockingStateAttributes.new
        body.state_name = state_name
        body.service = service
        body.is_block_change = is_block_change
        body.is_block_entitlement = is_block_entitlement
        body.is_block_billing = is_block_billing

        self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/block",
                        body.to_json,
                        params,
                        {
                            :user => user,
                            :reason => reason,
                            :comment => comment,
                        }.merge(options)
        blocking_states(nil, nil, 'NONE', options)
      end

      def cba_rebalancing(user = nil, reason = nil, comment = nil, options = {})
        self.class.put "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/cbaRebalancing",
                        {},
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end

      def invoice_payments(audit='NONE', with_plugin_info = false, with_attempts = false, options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoicePayments",
                       {
                           :audit                    => audit,
                           :withPluginInfo       => with_plugin_info,
                           :withAttempts => with_attempts
                       },
                       options,
                       InvoicePayment
      end

      def audit(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/auditLogs",
                       {},
                       options,
                       AuditLog
      end

    end
  end
end
