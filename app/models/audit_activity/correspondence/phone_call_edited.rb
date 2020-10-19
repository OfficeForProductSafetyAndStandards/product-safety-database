module AuditActivity
  module Correspondence
    class PhoneCallEdited < AuditActivity::Correspondence::Base
      belongs_to :correspondence, class_name: "Correspondence::PhoneCall"

      def title(_viewing_user)
        correspondence.overview
      end

      def self.build_metadata
        {}
      end

      def restricted_title(_user)
        "Phone call edited"
      end

    private

      def subtitle_slug
        "Phone call"
      end
    end
  end
end
