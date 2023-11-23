require "active_record_extended"
require "govuk/components"
require "govuk_design_system_formbuilder"

module SupportPortal
  class Engine < ::Rails::Engine
    isolate_namespace SupportPortal

    initializer "support_portal.assets.precompile" do |app|
      app.config.assets.precompile << "support_portal_manifest.js"
    end

    if Rails.env.production?
      initializer "action_controller" do |app|
        # Override `default_url_options` in the parent app
        # so that Devise redirects correctly
        app.config.action_controller.default_url_options = {
          host: ENV["PSD_HOST_SUPPORT"],
          protocol: "https"
        }
      end
    end
  end
end
