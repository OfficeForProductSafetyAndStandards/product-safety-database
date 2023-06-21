require "govuk/components"
require "govuk_design_system_formbuilder"

module Prism
  class Engine < ::Rails::Engine
    isolate_namespace Prism

    initializer "prism.assets.precompile" do |app|
      app.config.assets.precompile << "prism_manifest.js"
    end
  end
end
