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
  end
end
