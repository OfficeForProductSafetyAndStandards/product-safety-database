require "rails_helper"

RSpec.describe Investigation::Enquiry do
  let(:factory) { :enquiry }

  it_behaves_like "an Investigation"
end
