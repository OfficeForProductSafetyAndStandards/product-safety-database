class Investigation < ApplicationRecord
  require_dependency "investigation"
  class EnquiryDecorator < InvestigationDecorator

    def should_display_date_received?
      date_received?
    end

    def should_display_received_by?
      received_type?
    end

    def hint_for_contact_details
      h.tag.span(h.permissions_hint("enquiry contact details"), class: "govuk-hint")
    end
  end
end
