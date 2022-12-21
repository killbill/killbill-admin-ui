Rails.application.config.assets.precompile += %w( kaui/*.png kaui/*.css kaui_manifest.js)
Rails.application.config.assets.paths << Rails.root.join('node_modules')
