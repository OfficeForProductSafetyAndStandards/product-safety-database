module AuditActivity
  module Product
    class DestroyDecorator < ActivityDecorator
      def title(_viewing_user)
        "#{metadata.dig('product', 'name')} removed"
      end
    end
  end
end
