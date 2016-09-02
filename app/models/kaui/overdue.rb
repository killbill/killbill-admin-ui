class Kaui::Overdue < KillBillClient::Model::Overdue

  class << self


    def from_overdue_form_model(view_form_model)
      result = KillBillClient::Model::Overdue.new
      result.initial_reevaluation_interval = nil # TODO
      result.overdue_states = []
      view_form_model["states"].each do |state_model|

        state = KillBillClient::Model::OverdueStateConfig.new
        state.name = state_model["name"]
        state.auto_reevaluation_interval_days = nil # TODO
        state.external_message = state_model["external_message"]
        state.is_clear_state = state_model["is_clear_state"].nil? ? false : state_model["is_clear_state"]
        state.block_changes = state_model["block_changes"].nil? ? false : state_model["block_changes"]
        if state_model["subscription_cancellation_policy"] == "NO_CANCELLATION"
          state.disable_entitlement = false
          state.subscription_cancellation_policy = nil
        else
          state.disable_entitlement = true
          state.subscription_cancellation_policy = state_model["subscription_cancellation_policy"].blank? ? :NONE : state_model["subscription_cancellation_policy"].to_s.gsub!(/POLICY_/, '')
        end

        if state_model["condition"]
          state.condition = KillBillClient::Model::OverdueCondition.new
          if state_model["condition"]["time_since_earliest_unpaid_invoice_equals_or_exceeds"]
            state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds = KillBillClient::Model::DurationAttributes.new
            state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds.unit = "DAYS"
            state.condition.time_since_earliest_unpaid_invoice_equals_or_exceeds.number = state_model["condition"]["time_since_earliest_unpaid_invoice_equals_or_exceeds"]
          end
          state.condition.control_tag_inclusion = state_model["condition"]["control_tag_inclusion"] if !state_model["condition"]["control_tag_inclusion"].blank?
          state.condition.control_tag_exclusion = state_model["condition"]["control_tag_exclusion"] if !state_model["condition"]["control_tag_exclusion"].blank?
        end

        result.overdue_states << state
      end
      # We reversed them to display on the form , so we have to reverse them back before uploading new config
      result.overdue_states.reverse!

      result
    end

    def get_overdue_json(options)
      result = KillBillClient::Model::Overdue.get_tenant_overdue_config('json', options)
      class << result
        attr_accessor :has_states
      end
      result.has_states = result.overdue_states.size > 0 && result.overdue_states[0].is_clear_state
      result
    end

  end

end

