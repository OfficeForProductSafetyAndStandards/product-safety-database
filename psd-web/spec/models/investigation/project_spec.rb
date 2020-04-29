require "rails_helper"

RSpec.describe Investigation::Project, :with_stubbed_mailer do
  let(:factory) { :project }

  it_behaves_like "an Investigation"
end
