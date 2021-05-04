module AuditActivity
  module Business
    class DestroyDecorator < ActivityDecorator
      def title(_viewing_user)
        "Removed: #{metadata.dig('business', 'trading_name')}"
      end

      def reason
        metadata.dig("reason")
      end

      def business_id
        metadata.dig("business", "id")
      end
    end
  end
end
