require "rails_helper"

RSpec.describe TeamDecorator do
  subject(:decorated_team) { team.decorate }

  let(:team) { build(:team) }

  describe "#assignee_short_name" do
    it { expect(decorated_team.assignee_short_name).to eq(team.display_name) }
  end
end
