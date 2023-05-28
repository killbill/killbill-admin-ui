# frozen_string_literal: true

module Kaui
  class Overdue < KillBillClient::Model::Overdue
    class << self
      def from_overdue_form_model(view_form_model)
        result = KillBillClient::Model::Overdue.new
        result.initial_reevaluation_interval = nil # TODO
        result.overdue_states = []
        view_form_model['states'].each do |state_model|
          state = KillBillClient::Model::OverdueStateConfig.new
          state.name = state_model['name']
          state.auto_reevaluation_interval_days = nil
          state.external_message = state_model['external_message']
          state.is_clear_state = state_model['is_clear_state'].nil? ? false : state_model['is_clear_state']
          state.is_block_changes = state_model['is_block_changes']
          if state_model['subscription_cancellation_policy'] == :NONE.to_s
            state.is_disable_entitlement = false
            state.subscription_cancellation_policy = nil
          else
            state.is_disable_entitlement = true
            state.subscription_cancellation_policy = state_model['subscription_cancellation_policy'].blank? ? :NONE : state_model['subscription_cancellation_policy'].to_s.gsub!(/POLICY_/, '')
          end

          if state_model['condition']
            state.condition = KillBillClient::Model::OverdueCondition.new
            if state_model['condition']['time_since_earliest_unpaid_invoice_equals_or_exceeds']
              state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds = KillBillClient::Model::DurationAttributes.new
              state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds.unit = 'DAYS'
              state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds.number = state_model['condition']['time_since_earliest_unpaid_invoice_equals_or_exceeds']
            end
            state.condition.number_of_unpaid_invoices_equals_or_exceeds = state_model['condition']['number_of_unpaid_invoices_equals_or_exceeds']
            state.condition.total_unpaid_invoice_balance_equals_or_exceeds = state_model['condition']['total_unpaid_invoice_balance_equals_or_exceeds']
            state.condition.control_tag_inclusion = format_tag_condition(state_model['condition']['control_tag_inclusion'])
            state.condition.control_tag_exclusion = format_tag_condition(state_model['condition']['control_tag_exclusion'])
          end

          result.overdue_states << state
        end
        # We reversed them to display on the form , so we have to reverse them back before uploading new config
        result.overdue_states.reverse!

        result
      end

      def get_tenant_overdue_config(options)
        overdue_xml = KillBillClient::Model::Overdue.get_tenant_overdue_config_xml(options)
        Nokogiri::XML(overdue_xml, &:noblanks)
      end

      def get_overdue_json(options)
        result = KillBillClient::Model::Overdue.get_tenant_overdue_config_json(options)
        class << result
          attr_accessor :has_states
        end
        result.has_states = result.overdue_states.size.positive? && result.overdue_states[0].is_clear_state

        result.overdue_states.each do |state|
          class << state
            attr_accessor :subscription_cancellation
          end
          state.subscription_cancellation = if state.is_disable_entitlement
                                              state.subscription_cancellation_policy ? "POLICY_#{state.subscription_cancellation_policy}".to_sym : :NONE
                                            else
                                              :NONE
                                            end
          next unless state.condition.nil?

          state.condition = KillBillClient::Model::OverdueCondition.new
          state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds = KillBillClient::Model::DurationAttributes.new
          state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds.unit = 'DAYS'
          state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds.number = 0
          state.condition.number_of_unpaid_invoices_equals_or_exceeds = 0
          state.condition.total_unpaid_invoice_balance_equals_or_exceeds = 0
          state.condition.control_tag_inclusion = :NONE
          state.condition.control_tag_exclusion = :NONE
        end
        result
      end

      def format_tag_condition(control_tag)
        return nil if control_tag.blank? || control_tag == :NONE.to_s

        control_tag
      end
    end
  end
end
