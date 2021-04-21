module AuditActivity
  module Business
    class DestroyDecorator < ActivityDecorator
      def title(_viewing_user)
        "Removed: #{metadata.dig('business', 'trading_name')}"
      end
    end
  end
end
