module Shared
  module Web
    module ApplicationHelper
      include ::Webpacker::Helper

      def current_webpacker_instance
        Shared::Web.webpacker
      end
    end
  end
end
