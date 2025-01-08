module AuditActivity
  module Business
    class AddDecorator < ActivityDecorator
      def title(_viewing_user)
        "Business added"
      end

      def relationship
        metadata.dig("investigation_business", "relationship")
      end
    end
  end
end
