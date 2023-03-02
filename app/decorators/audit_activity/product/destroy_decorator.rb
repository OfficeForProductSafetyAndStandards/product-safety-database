module AuditActivity
  module Product
    class DestroyDecorator < ActivityDecorator
      def title(_viewing_user)
        "#{metadata.dig('investigation_product', 'name')} removed"
      end
    end
  end
end
