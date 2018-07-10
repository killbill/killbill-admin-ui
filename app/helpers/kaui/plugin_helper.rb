module Kaui
  module PluginHelper
    # including plugin that are installed
    def plugin_repository
      plugins = []
      plugin_repository = Kaui::AdminTenant.get_plugin_repository
      plugin_repository.each_pair do |key, info|
        plugins << {
          plugin_key: plugin_key(key.to_s, info),
          plugin_name: plugin_name(key.to_s, info),
          plugin_type: info[:type],
          installed: false
        }
      end

      installed_plugins = installed_plugins(plugins)

      plugins.sort! { |a, b| a[:plugin_key] <=> b[:plugin_key] }
      plugins.each { |plugin| installed_plugins << plugin }

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

      def installed_plugins(plugins)
        installed_plugins = []
        nodes_info = KillBillClient::Model::NodesInfo.nodes_info(Kaui.current_tenant_user_options(current_user, session)) || []
        plugins_info = nodes_info.first.plugins_info || []

        plugins_info.each do |plugin|
          next if plugin.version.nil?
          # do not allow duplicate
          next if installed_plugins.any? { |p| p[:plugin_name].eql?(plugin.plugin_name) }
          plugin_key = Kaui::AdminTenant.rewrite_plugin_key(plugin.plugin_key) unless plugin.plugin_key.nil?
          installed_plugins << {
              plugin_key: plugin_key,
              plugin_name: plugin.plugin_name,
              plugin_type: find_plugin_type(plugins, plugin_key),
              installed: true
          }
        end

        # to_s to handle nil
        installed_plugins.sort! { |a,b| a[:plugin_key].to_s <=> b[:plugin_key].to_s }
      end

      def find_plugin_type(plugins, plugin_key_to_search)
        plugins.each do |plugin|
          if plugin[:plugin_key] == plugin_key_to_search
            return plugin[:plugin_type]
          end
        end

        return nil
      end
  end
end
