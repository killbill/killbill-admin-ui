module KillBillClient
  module Model
    class InvoiceItem < InvoiceItemAttributes

      KILLBILL_API_INVOICE_ITEMS_PREFIX = "#{KILLBILL_API_PREFIX}/invoiceItems"

      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      has_custom_fields KILLBILL_API_INVOICE_ITEMS_PREFIX, :invoice_item_id
      has_tags KILLBILL_API_INVOICE_ITEMS_PREFIX, :invoice_item_id
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_audit_logs_with_history KILLBILL_API_INVOICE_ITEMS_PREFIX, :invoice_item_id


      # DO NOT DELETE THIS METHOD
      def tags(included_deleted = false, audit = 'NONE', options = {})
        params = {}
        # Non-standard, required, parameter
        params[:accountId] = account_id
        params[:includedDeleted] = included_deleted if included_deleted
        params[:audit] = audit
        self.class.get "#{KILLBILL_API_INVOICE_ITEMS_PREFIX}/#{invoice_item_id}/tags",
                       params,
                       options,
                       Tag
      end

      # DO NOT DELETE THIS METHOD
      def add_tags_from_definition_ids(tag_definition_ids, user, reason, comment, options)
        created_tag = self.class.post "#{KILLBILL_API_INVOICE_ITEMS_PREFIX}/#{invoice_item_id}/tags",
                                      tag_definition_ids,
                                      {},
                                      {
                                          :user    => user,
                                          :reason  => reason,
                                          :comment => comment,
                                      }.merge(options),
                                      Tag
        tags(false, 'NONE', options) unless created_tag.nil?
      end

      def create(auto_commit = false, user = nil, reason = nil, comment = nil, options = {})
        created_invoice_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/charges/#{account_id}",
                                               [to_hash].to_json,
                                               {:autoCommit => auto_commit},
                                               {
                                                   :user    => user,
                                                   :reason  => reason,
                                                   :comment => comment,
                                               }.merge(options)
        created_invoice_item.first.refresh(options, Invoice)
      end

      # Adjust an invoice item
      #
      # Required: account_id, invoice_id, invoice_item_id
      # Optional: amount, currency
      def update(user = nil, reason = nil, comment = nil, options = {})
        adjusted_invoice_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}",
                                                to_json,
                                                {},
                                                {
                                                    :user    => user,
                                                    :reason  => reason,
                                                    :comment => comment,
                                                }.merge(options)
        adjusted_invoice_item.refresh(options, Invoice)
      end

      # Delete CBA
      #
      # Required: invoice_id, invoice_item_id
      def delete(user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/#{invoice_item_id}/cba",
                          to_json,
                          {
                              :accountId => account_id
                          },
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def create_tax_item(auto_commit = false, user = nil, reason = nil, comment = nil, options = {})
        created_tax_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/taxes/#{account_id}",
                                               [to_hash].to_json,
                                               {:autoCommit => auto_commit},
                                               {
                                                   :user    => user,
                                                   :reason  => reason,
                                                   :comment => comment,
                                               }.merge(options)
        created_tax_item.first.refresh(options, Invoice)
      end
    end
  end
end
