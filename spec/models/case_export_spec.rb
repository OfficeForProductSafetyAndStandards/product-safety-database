require "rails_helper"

RSpec.describe CaseExport, :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  let(:organisation) { create(:organisation) }
  let(:team) { create(:team, organisation: organisation) }
  let(:user) { create(:user, :activated, organisation: organisation, team: team, has_viewed_introduction: true) }
  let(:other_user_same_team) { create(:user, :activated, name: "other user same team", organisation: organisation, team: team) }
  let!(:investigation) { create(:allegation, creator: user) }
  let!(:other_user_investigation) { create(:allegation, creator: other_user_same_team) }
  let(:cases) { [investigation, other_user_investigation] }
  let!(:case_export) { described_class.create }

  describe "#export" do
    before do
      case_export.export(cases)
    end

    let!(:exported_data) { case_export.export_file.open { |file| Roo::Excelx.new(file) } }

    it "exports one Cases sheet" do
      expect(exported_data.sheets).to eq %w[Cases]
    end

    # rubocop:disable RSpec/MultipleExpectations

    context "with Cases sheet" do
      let!(:sheet) { exported_data.sheet("Cases") }

      it "exports ID" do
        expect(sheet.cell(1, 1)).to eq "ID"
        expect(sheet.cell(2, 1)).to eq investigation.pretty_id
        expect(sheet.cell(3, 1)).to eq other_user_investigation.pretty_id
      end

      it "exports Status" do
        expect(sheet.cell(1, 2)).to eq "Status"
        expect(sheet.cell(2, 2)).to eq(investigation.is_closed? ? "Closed" : "Open")
        expect(sheet.cell(3, 2)).to eq(other_user_investigation.is_closed? ? "Closed" : "Open")
      end

      it "exports Title" do
        expect(sheet.cell(1, 3)).to eq "Title"
        expect(sheet.cell(2, 3)).to eq investigation.title
        expect(sheet.cell(3, 3)).to eq other_user_investigation.title
      end

      it "exports Type" do
        expect(sheet.cell(1, 4)).to eq "Type"
        expect(sheet.cell(2, 4)).to eq investigation.type
        expect(sheet.cell(3, 4)).to eq other_user_investigation.type
      end

      it "exports Description" do
        expect(sheet.cell(1, 5)).to eq "Description"
        expect(sheet.cell(2, 5)).to eq investigation.description
        expect(sheet.cell(3, 5)).to eq other_user_investigation.description
      end

      it "exports Product_Category" do
        expect(sheet.cell(1, 6)).to eq "Product_Category"
        expect(sheet.cell(2, 6)).to eq investigation.categories.presence&.join(", ")
        expect(sheet.cell(3, 6)).to eq other_user_investigation.categories.presence&.join(", ")
      end

      it "exports Hazard_Type" do
        expect(sheet.cell(1, 7)).to eq "Hazard_Type"
        expect(sheet.cell(2, 7)).to eq investigation.hazard_type
        expect(sheet.cell(3, 7)).to eq other_user_investigation.hazard_type
      end

      it "exports Coronavirus_Related" do
        expect(sheet.cell(1, 8)).to eq "Coronavirus_Related"
        expect(sheet.cell(2, 8)).to eq investigation.coronavirus_related?.to_s
        expect(sheet.cell(3, 8)).to eq other_user_investigation.coronavirus_related?.to_s
      end

      it "exports Risk_Level" do
        expect(sheet.cell(1, 9)).to eq "Risk_Level"
        expect(sheet.cell(2, 9)).to eq investigation.decorate.risk_level_description
        expect(sheet.cell(3, 9)).to eq other_user_investigation.decorate.risk_level_description
      end

      it "exports Case_Owner_Team" do
        expect(sheet.cell(1, 10)).to eq "Case_Owner_Team"
        expect(sheet.cell(2, 10)).to eq investigation.owner_team&.name
        expect(sheet.cell(3, 10)).to eq other_user_investigation.owner_team&.name
      end

      it "exports Case_Owner_User" do
        expect(sheet.cell(1, 11)).to eq "Case_Owner_User"
        expect(sheet.cell(2, 11)).to eq investigation.owner_user&.name
        expect(sheet.cell(3, 11)).to eq other_user_investigation.owner_user&.name
      end

      it "exports Source" do
        expect(sheet.cell(1, 12)).to eq "Source"
        expect(sheet.cell(2, 12)).to eq investigation.creator_user&.name
        expect(sheet.cell(3, 12)).to eq other_user_investigation.creator_user&.name
      end

      it "exports Complainant_Type" do
        expect(sheet.cell(1, 13)).to eq "Complainant_Type"
        expect(sheet.cell(2, 13)).to eq investigation.complainant&.complainant_type
        expect(sheet.cell(3, 13)).to eq other_user_investigation.complainant&.complainant_type
      end

      it "exports Products" do
        # TODO: This will be flaky if Faker generates two dupes
        expect(sheet.cell(1, 14)).to eq "Products"
        expect(sheet.cell(2, 14)).to eq "0"
        expect(sheet.cell(3, 14)).to eq "0"
      end

      it "exports Businesses" do
        expect(sheet.cell(1, 15)).to eq "Businesses"
        expect(sheet.cell(2, 15)).to eq "0"
        expect(sheet.cell(3, 15)).to eq "0"
      end

      it "exports Activities" do
        expect(sheet.cell(1, 16)).to eq "Activities"
        expect(sheet.cell(2, 16)).to eq "1"
        expect(sheet.cell(3, 16)).to eq "1"
      end

      it "exports Correspondences" do
        expect(sheet.cell(1, 17)).to eq "Correspondences"
        expect(sheet.cell(2, 17)).to eq "0"
        expect(sheet.cell(3, 17)).to eq "0"
      end

      it "exports Corrective_Actions" do
        expect(sheet.cell(1, 18)).to eq "Corrective_Actions"
        expect(sheet.cell(2, 18)).to eq "0"
        expect(sheet.cell(3, 18)).to eq "0"
      end

      it "exports Tests" do
        expect(sheet.cell(1, 19)).to eq "Tests"
        expect(sheet.cell(2, 19)).to eq "0"
        expect(sheet.cell(3, 19)).to eq "0"
      end

      it "exports Risk_Assessments" do
        expect(sheet.cell(1, 20)).to eq "Risk_Assessments"
        expect(sheet.cell(2, 20)).to eq "0"
        expect(sheet.cell(3, 20)).to eq "0"
      end

      it "exports Date_Created" do
        expect(sheet.cell(1, 21)).to eq "Date_Created"
        expect(sheet.cell(2, 21)).to eq investigation.created_at&.to_s
        expect(sheet.cell(3, 21)).to eq other_user_investigation.created_at&.to_s
      end

      it "exports Last_Updated" do
        expect(sheet.cell(1, 22)).to eq "Last_Updated"
        expect(sheet.cell(2, 22)).to eq investigation.updated_at&.to_s
        expect(sheet.cell(3, 22)).to eq other_user_investigation.updated_at&.to_s
      end

      it "exports Date_Closed" do
        expect(sheet.cell(1, 23)).to eq "Date_Closed"
        expect(sheet.cell(2, 23)).to eq investigation.date_closed&.to_s
        expect(sheet.cell(3, 23)).to eq other_user_investigation.date_closed&.to_s
      end

      it "exports Date_Validated" do
        expect(sheet.cell(1, 24)).to eq "Date_Validated"
        expect(sheet.cell(2, 24)).to eq investigation.risk_validated_at&.to_s
        expect(sheet.cell(3, 24)).to eq other_user_investigation.risk_validated_at&.to_s
      end

      it "exports Case_Creator_Team" do
        expect(sheet.cell(1, 25)).to eq "Case_Creator_Team"
        expect(sheet.cell(2, 25)).to eq investigation.creator_user&.team&.name
        expect(sheet.cell(3, 25)).to eq other_user_investigation.creator_user&.team&.name
      end

      it "exports Notifying_Country" do
        expect(sheet.cell(1, 26)).to eq "Notifying_Country"
        expect(sheet.cell(2, 26)).to eq "England"
        expect(sheet.cell(3, 26)).to eq "England"
      end

      it "exports Reported_as" do
        expect(sheet.cell(1, 27)).to eq "Reported_as"
        expect(sheet.cell(2, 27)).to eq investigation.reported_reason
        expect(sheet.cell(3, 27)).to eq other_user_investigation.reported_reason
      end
    end

    # rubocop:enable RSpec/MultipleExpectations
  end
end
