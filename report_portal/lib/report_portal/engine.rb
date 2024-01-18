require "govuk/components"
require "govuk_design_system_formbuilder"

module ReportPortal
  class Engine < ::Rails::Engine
    isolate_namespace ReportPortal

    initializer "report_portal.assets.precompile" do |app|
      app.config.assets.precompile << "report_portal_manifest.js"
    end
  end
end
