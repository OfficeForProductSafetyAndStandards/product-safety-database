class Investigation < ApplicationRecord
  require_dependency "investigation"
  class EnquiryDecorator < InvestigationDecorator
  end
end
