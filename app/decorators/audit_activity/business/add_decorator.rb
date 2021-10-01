module AuditActivity
  module Business
    class AddDecorator < ActivityDecorator
      def title(_viewing_user)
        "Business added"
      end
    end
  end
end
