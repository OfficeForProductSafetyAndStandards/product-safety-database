require "rails_helper"

RSpec.describe TeamDecorator do
  let(:team) { build(:team) }

  subject { team.decorate }

  describe  "#assignee_short_name" do
    it { expect(subject.assignee_short_name).to eq(team.display_name) }
  end
end
