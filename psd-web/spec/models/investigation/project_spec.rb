require "rails_helper"

RSpec.describe Investigation::Project do
  let(:factory) { :project }

  it_behaves_like "an Investigation"
end
