require "rails_helper"

RSpec.describe TeamDecorator do
  subject { team.decorate }

  let(:team) { build(:team) }


  describe "#assignee_short_name" do
    it { expect(subject.assignee_short_name).to eq(team.display_name) }
  end
end
