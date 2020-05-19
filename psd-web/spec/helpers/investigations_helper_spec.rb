require "rails_helper"

RSpec.describe InvestigationsHelper, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:investigation) { create(:investigation) }

  describe "#team_list_html" do
    context "when only team was added" do
      it { expect(helper.team_list_html(investigation)).to eq(investigation.teams_with_access.first.name) }
    end

    context "when many teams have been added to the case" do
      before do
        AddTeamToAnInvestigation.call(
          team_id: create(:team).id,
          investigation: investigation,
          current_user: create(:user),
          include_message: false
        )
      end

      let(:team_list_html) { Capybara.string(helper.team_list_html(investigation)) }

      it "displays each teams's name with access to the investigation" do
        investigation.team_with_access.each { |team| expect(team_list_html).to have_css("ul li", text: team.name) }
      end
    end
  end
end
