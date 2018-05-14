module Kaui
  module PluginHelper
    # including plugin that are installed
    def plugin_repository
      plugins = []
      plugin_repository = Kaui::AdminTenant::get_plugin_repository
      installed_plugins = installed_plugins()

      plugin_repository.each_pair do |key, info|
        found_plugin = installed_plugins.reject! { |p| p.plugin_key.eql?(key.to_s) }
        plugins << {
            plugin_key: plugin_key(key.to_s, info),
            plugin_name: plugin_name(key.to_s, info),
            plugin_type: info[:type],
            installed: !found_plugin.nil?
        }
      end

      installed_plugins.each do |plugin|
        plugins << {
            plugin_key: plugin.plugin_key,
            plugin_name: plugin.plugin_name,
            plugin_type: nil,
            installed: true
        }
      end

      plugins.sort! { |a,b| a[:plugin_key] <=> b[:plugin_key] && b[:installed].to_s <=> a[:installed].to_s }
      puts '.'*50
      puts plugins.to_json
      plugins
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
        if info[:artifact_id].nil?
          "#{key}"
        else
          "#{info[:artifact_id].gsub('killbill-','').gsub('-plugin','')}"
        end
      end

      def installed_plugins
        nodes_info = KillBillClient::Model::NodesInfo.nodes_info(Kaui.current_tenant_user_options(current_user, session)) || []
        plugins_info = nodes_info.first.plugins_info || []

        plugins_info.select { |plugin| !plugin.version.nil?}
      end
  end
end