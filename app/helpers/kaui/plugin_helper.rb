module Kaui
  module PluginHelper

    def plugin_repository
      installed_plugins
    end

    private

      def plugin_name(key, info)
        if info[:artifact_id].nil?
          "killbill-#{key}"
        else
          "killbill-#{info[:artifact_id].gsub('killbill-','').gsub('-plugin','')}"
        end
      end

      def plugin_key(key, info)
        # hack:: replace paypal key with paypal_express, to set configuration and allow the ui to find the right configuration inputs
        if key.eql?('paypal')
          'paypal_express'
        else
          "#{key}"
        end
      end

      def installed_plugins
        installed_plugins = []
        nodes_info = KillBillClient::Model::NodesInfo.nodes_info(Kaui.current_tenant_user_options(current_user, session)) || []
        plugins_info = nodes_info.first.plugins_info || []

        plugins_info.each do |plugin|
          next if plugin.version.nil?
          # do not allow duplicate
          next if installed_plugins.any? { |p| p[:plugin_name].eql?(plugin.plugin_name) }
          plugin_key = plugin.plugin_key
          installed_plugins << {
              plugin_key: plugin_key,
              plugin_name: plugin.plugin_name,
              installed: true
          }
        end

        # to_s to handle nil
        installed_plugins.sort! { |a,b| a[:plugin_key].to_s <=> b[:plugin_key].to_s }
      end
  end
end
