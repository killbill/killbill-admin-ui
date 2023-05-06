# frozen_string_literal: true

module Kaui
  module UsStatesHelper
    def all_us_states
      us_states_yaml_file = File.join(File.dirname(__FILE__), 'us_states_helper.yml')
      states = YAML.load_file(us_states_yaml_file)

      states.map { |state| [state[:state_name], state[:abbreviation]] }
    end
  end
end
