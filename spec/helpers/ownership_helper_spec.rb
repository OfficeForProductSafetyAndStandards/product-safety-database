require "rails_helper"

RSpec.describe OwnershipHelper do
  describe "#add_your_team_values", :with_stubbed_elasticsearch, :with_stubbed_mailer do
    let(:user)           { create(:user) }
    let(:another_user)   { create(:user) }
    let!(:investigation) { create(:allegation, creator: user) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    context "when investigation owner is current user" do
      it 'returns expected items' do
        expect(helper.add_your_team_values([], investigation, '')).to eq([
          { divider: "Your team" },
          { text: investigation.owner.decorate.display_name(viewer: helper.current_user), value: investigation.owner.id, checked: true },
          { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: "" } },
          { text: helper.current_user.team.decorate.display_name(viewer: helper.current_user), value: helper.current_user.team.id, checked: false }
        ])
      end
    end

    context "when investigation owner is current user's team" do
      before do
        allow(investigation).to receive(:owner) { helper.current_user.team }
      end

      it 'returns expected items' do
        expect(helper.add_your_team_values([], investigation, '')).to eq([
          { divider: "Your team" },
          { text: investigation.owner.decorate.display_name(viewer: helper.current_user), value: investigation.owner.id, checked: true },
          { text: helper.current_user.decorate.display_name(viewer: helper.current_user), value: helper.current_user.id, checked: false },
          { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: "" } }
        ])
      end
    end

    context "when investigation owner is neither current user nor current user`s team" do
      before do
        allow(investigation).to receive(:owner) { another_user }
      end

      it 'returns expected items' do
        expect(helper.add_your_team_values([], investigation, '')).to eq([
          { divider: "Your team" },
          { text: investigation.owner.decorate.display_name(viewer: helper.current_user), value: investigation.owner.id, checked: true },
          { text: helper.current_user.decorate.display_name(viewer: helper.current_user), value: helper.current_user.id, checked: false },
          { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: "" } },
          { text: helper.current_user.team.decorate.display_name(viewer: helper.current_user), value: helper.current_user.team.id, checked: false }
        ])
      end
    end
  end
end
