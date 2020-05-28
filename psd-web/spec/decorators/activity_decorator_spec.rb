require "rails_helper"

RSpec.describe ActivityDecorator do
  subject { investigation.activities.first.decorate }

  let(:investigation) { create(:investigation).decorate }

  describe "#display_title" do
    context "when the viewing user" do
    end
  end
end
