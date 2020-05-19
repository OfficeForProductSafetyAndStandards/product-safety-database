require "rails_helper"

RSpec.describe InvestigationsHelper, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:sourceable) { create(:user) }
  let(:investigation) { create(:investigation, source: UserSource.new(user: sourceable)).decorate }

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
        investigation.teams_with_access.each { |team| expect(team_list_html).to have_css("ul li", text: team.name) }
      end
    end
  end

  describe "#source_details_rows" do
    describe "contact details for a viewing user" do
      let(:viewing_user_organisation) { sourceable.organisation }
      let(:viewing_user_team) { sourceable.team }
      let(:viewing_user) { create(:user, organisation: viewing_user_organisation, team: viewing_user_team) }
      let!(:complainant) { create(:complainant_Consumer, investigation: investigation).decorate }

      context "when in the same organisation as the investigation creator" do
        context "when also is in a team with access to the case" do
          it "shows the enquiry contact details" do
            expect(source_details_rows(investigation, viewing_user)).to include(key: { text: "Contact details" }, value: { text: complainant.contact_details(viewing_user) })
          end
        end
      end

      context "when not in the same organisation as the investigation creator" do
        let(:viewing_user_organisation) { create(:organisation) }

        it "shows the GDPR warning" do
          expect(source_details_rows(investigation, viewing_user)).to include(key: { text: "Contact details" }, value: { text: "Reporter details are restricted because they contain GDPR protected data." })
        end
      end

      context "when in a team not on the case" do
        let(:viewing_user_team) { create(:team, organisation: viewing_user_organisation) }

        it "does not shows the restriction message" do
          expect(source_details_rows(investigation, viewing_user)).to include(key: { text: "Contact details" }, value: { text: complainant.contact_details(viewing_user) })
        end

        context "when the investigation is an enquiry" do
          let(:investigation) { create(:enquiry, source: UserSource.new(user: sourceable)).decorate }

          it "shows the restriction message" do
            expect(source_details_rows(investigation, viewing_user)).to include(key: { text: "Contact details" }, value: { text: /Only teams added to the case can view enquiry contact details/ })
          end

          it "does not shows the contact details" do
            expect(source_details_rows(investigation, viewing_user)).not_to include(key: { text: "Contact details" }, value: { text: /Regexp.escape(complainant.contact_details)/ })
          end
        end
      end
    end
  end
end
