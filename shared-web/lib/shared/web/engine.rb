module Shared
  module Web
    class Engine < ::Rails::Engine
      isolate_namespace Shared::Web

      initializer "webpacker.proxy" do |app|
        insert_middleware = begin
                              Shared::Web.webpacker.config.dev_server.present?
                            rescue
                              nil
                            end
        next unless insert_middleware

        app.middleware.insert_before(
          0, Webpacker::DevServerProxy, # "Webpacker::DevServerProxy" if Rails version < 5
          ssl_verify_none: true,
          webpacker: Shared::Web.webpacker
        )
      end
    end
  end
end
