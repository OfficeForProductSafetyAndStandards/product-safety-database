require "rails_helper"

RSpec.describe Investigation::Enquiry, :with_stubbed_mailer do
  let(:factory) { :enquiry }

  it_behaves_like "an Investigation"
end
