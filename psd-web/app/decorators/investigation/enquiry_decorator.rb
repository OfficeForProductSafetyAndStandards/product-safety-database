class Investigation < ApplicationRecord
  require_dependency "investigation"
  class EnquiryDecorator < InvestigationDecorator
  private

    def should_display_date_received?
      date_received?
    end

    def should_display_received_by?
      received_type?
    end

    def contact_details_for_display(viewing_user)
      h.concat(h.tag.span(h.permissions_hint("enquiry contact details"), class: "govuk-hint"))
      h.concat(super)
    end
  end
end
