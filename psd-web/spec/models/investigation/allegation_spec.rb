require "rails_helper"

RSpec.describe Investigation::Allegation, :with_stubbed_mailer do
  let(:factory) { :allegation }

  it_behaves_like "an Investigation"
end
