require "rails_helper"

RSpec.describe Investigation::Allegation do
  let(:factory) { :allegation }

  it_behaves_like "an Investigation"
end
