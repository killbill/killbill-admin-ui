require 'timeout'

module KillBillClient
  module Model
    class NodesInfo < NodeInfoAttributes

      KILLBILL_NODES_INFO_PREFIX = "#{KILLBILL_API_PREFIX}/nodesInfo"

      has_many :plugins_info, KillBillClient::Model::PluginInfoAttributes

      class << self

        def nodes_info(options = {})
          get KILLBILL_NODES_INFO_PREFIX,
              {},
              options
        end


        def start_plugin(plugin_key, plugin_version=nil, plugin_props=[], local_node_only=false, user = nil, reason = nil, comment = nil, options = {}, timeout_sec=15, sleep_sec=1)

          proc_condition = create_proc_condition_for_wait_for_plugin_command_completion(options, plugin_key, plugin_version, "RUNNING")

          trigger_node_command_wait_for_plugin_command_completion(:START_PLUGIN, plugin_key, plugin_version, plugin_props, local_node_only, user, reason, comment, options, timeout_sec, sleep_sec, &proc_condition)
        end

        def stop_plugin(plugin_key, plugin_version=nil, plugin_props=[], local_node_only=false, user = nil, reason = nil, comment = nil, options = {}, timeout_sec=15, sleep_sec=1)

          proc_condition = create_proc_condition_for_wait_for_plugin_command_completion(options, plugin_key, plugin_version, "STOPPED")

          trigger_node_command_wait_for_plugin_command_completion(:STOP_PLUGIN, plugin_key, plugin_version, plugin_props, local_node_only, user, reason, comment, options, timeout_sec, sleep_sec, &proc_condition)
        end


        def install_plugin(plugin_key, plugin_version=nil, plugin_props=[], local_node_only=false, user = nil, reason = nil, comment = nil, options = {}, timeout_sec=30, sleep_sec=1)

          proc_condition = create_proc_condition_for_wait_for_plugin_command_completion(options, plugin_key, plugin_version, nil)

          trigger_node_command_wait_for_plugin_command_completion(:INSTALL_PLUGIN, plugin_key, plugin_version, plugin_props, local_node_only, user, reason, comment, options, timeout_sec, sleep_sec, &proc_condition)
        end

        def uninstall_plugin(plugin_key, plugin_version=nil, plugin_props=[], local_node_only=false, user = nil, reason = nil, comment = nil, options = {}, timeout_sec=15, sleep_sec=1)

          is_negate = true # We are looking for absence of plugin_info from result (after plugin got successfully uninstalled)
          proc_condition = create_proc_condition_for_wait_for_plugin_command_completion(options, plugin_key, plugin_version, nil, is_negate)

          trigger_node_command_wait_for_plugin_command_completion(:UNINSTALL_PLUGIN, plugin_key, plugin_version, plugin_props, local_node_only, user, reason, comment, options, timeout_sec, sleep_sec, &proc_condition)
        end


        def trigger_node_command(node_command, local_node_only, user = nil, reason = nil, comment = nil, options = {})
          post KILLBILL_NODES_INFO_PREFIX,
               node_command.to_json,
               {:localNodeOnly => local_node_only},
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end

        private

        def trigger_node_command_wait_for_plugin_command_completion(node_command_type, plugin_key, plugin_version, plugin_props, local_node_only, user, reason, comment, options, timeout_sec, sleep_sec, &proc_condition)
          # Idempotency : Check if already installed
          res = proc_condition.call
          return res if res

          node_command = KillBillClient::Model::NodeCommandAttributes.new
          node_command.is_system_command_type = true
          node_command.node_command_type = node_command_type
          node_command.node_command_properties = []
          node_command.node_command_properties << {:key => 'pluginKey', :value => plugin_key} if plugin_key
          node_command.node_command_properties << {:key => 'pluginVersion', :value => plugin_version} if plugin_version
          plugin_props.each do |e|
            node_command.node_command_properties << e
          end

          KillBillClient::Model::NodesInfo.trigger_node_command(node_command, local_node_only, user, reason, comment, options)

          wait_for_plugin_command_completion(node_command_type, plugin_key ,timeout_sec, sleep_sec, &proc_condition)
        end

        def create_proc_condition_for_wait_for_plugin_command_completion(options, plugin_key, plugin_version, state=nil, is_negate=false)
          proc_condition = Proc.new {
            node_infos = KillBillClient::Model::NodesInfo.nodes_info(options)

            res = true
            node_infos.each do |info|
              raw_node_res = info.plugins_info.find do |e|
                if e.plugin_key == plugin_key
                  if KillBillClient.logger
                    KillBillClient.log :info, 'NodesInfo  -> check for plugin command completion version_check=%s, state_check=%s' % [(plugin_version.nil? && e.is_selected_for_start) || plugin_version == e.version, state.nil? || e.state == state]
                  end
                end
                e.plugin_key == plugin_key && ((plugin_version.nil? && e.is_selected_for_start) || plugin_version == e.version) && (state.nil? ||  e.state == state)
              end
              node_res = is_negate ? !raw_node_res : raw_node_res
              res = res & node_res
            end
            res
          }
          proc_condition
        end

        def wait_for_plugin_command_completion(command, plugin, timeout_sec, sleep_sec)
          if KillBillClient.logger
            KillBillClient.log :info, "NodesInfo waiting for command='%s', plugin='%s'" % [command, plugin]
          end
          begin
            Timeout::timeout(timeout_sec) do
              while true do
                installed_plugin = yield
                return installed_plugin if installed_plugin
                sleep(sleep_sec)
              end
            end
          rescue Timeout::Error => e
            if KillBillClient.logger
              KillBillClient.log :warn, "NodesInfo timeout after %s sec for command='%s', plugin='%s'" % [timeout_sec, command, plugin]
            end
            raise e
          end
        end

      end

    end
  end
end
