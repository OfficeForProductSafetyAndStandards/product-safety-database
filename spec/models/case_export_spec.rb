require "rails_helper"

RSpec.describe CaseExport, :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, :with_stubbed_antivirus do
  let!(:organisation) { create(:organisation) }
  let!(:team) { create(:team, organisation: organisation) }
  let!(:user) { create(:user, :activated, organisation: organisation, team: team, has_viewed_introduction: true) }
  let!(:other_user_same_team) { create(:user, :activated, name: "other user same team", organisation: organisation, team: team) }
  let!(:investigation) { create(:allegation, creator: user).decorate }
  let!(:other_user_investigation) { create(:allegation, creator: other_user_same_team).decorate }
  let(:params) { { enquiry: "unchecked", project: "unchecked", sort_by: "recent", allegation: "unchecked", created_by: { id: "", me: "", my_team: "", someone_else: "" }, status_open: "true", teams_with_access: { my_team: "", other_team_with_access: "" } } }
  let(:case_export) { described_class.create!(user: user, params: params) }

  before { Investigation.__elasticsearch__.import force: true, refresh: :wait }

  describe "#export!" do
    let(:result) { case_export.export! }

    it "attaches the spreadsheet as a file" do
      result
      expect(case_export.export_file).to be_attached
    end
  end

  describe "#to_spreadsheet" do
    let(:spreadsheet) { case_export.to_spreadsheet.to_stream }
    let(:exported_data) { Roo::Excelx.new(spreadsheet) }
    let(:sheet) { exported_data.sheet("Cases") }

    # rubocop:disable RSpec/MultipleExpectations
    # rubocop:disable RSpec/ExampleLength
    it "exports the case data" do
      expect(exported_data.sheets).to eq %w[Cases]

      expect(sheet.cell(1, 1)).to eq "ID"
      expect(sheet.cell(2, 1)).to eq investigation.pretty_id
      expect(sheet.cell(3, 1)).to eq other_user_investigation.pretty_id

      expect(sheet.cell(1, 2)).to eq "Status"
      expect(sheet.cell(2, 2)).to eq(investigation.is_closed? ? "Closed" : "Open")
      expect(sheet.cell(3, 2)).to eq(other_user_investigation.is_closed? ? "Closed" : "Open")

      expect(sheet.cell(1, 3)).to eq "Title"
      expect(sheet.cell(2, 3)).to eq investigation.title
      expect(sheet.cell(3, 3)).to eq other_user_investigation.title

      expect(sheet.cell(1, 4)).to eq "Type"
      expect(sheet.cell(2, 4)).to eq investigation.type
      expect(sheet.cell(3, 4)).to eq other_user_investigation.type

      expect(sheet.cell(1, 5)).to eq "Description"
      expect(sheet.cell(2, 5)).to eq investigation.object.description
      expect(sheet.cell(3, 5)).to eq other_user_investigation.object.description

      expect(sheet.cell(1, 6)).to eq "Product_Category"
      expect(sheet.cell(2, 6)).to eq investigation.categories.presence&.join(", ")
      expect(sheet.cell(3, 6)).to eq other_user_investigation.categories.presence&.join(", ")

      expect(sheet.cell(1, 7)).to eq "Hazard_Type"
      expect(sheet.cell(2, 7)).to eq investigation.hazard_type
      expect(sheet.cell(3, 7)).to eq other_user_investigation.hazard_type

      expect(sheet.cell(1, 8)).to eq "Coronavirus_Related"
      expect(sheet.cell(2, 8)).to eq investigation.coronavirus_related?.to_s
      expect(sheet.cell(3, 8)).to eq other_user_investigation.coronavirus_related?.to_s

      expect(sheet.cell(1, 9)).to eq "Risk_Level"
      expect(sheet.cell(2, 9)).to eq investigation.decorate.risk_level_description
      expect(sheet.cell(3, 9)).to eq other_user_investigation.decorate.risk_level_description

      expect(sheet.cell(1, 10)).to eq "Case_Owner_Team"
      expect(sheet.cell(2, 10)).to eq investigation.owner_team&.name
      expect(sheet.cell(3, 10)).to eq other_user_investigation.owner_team&.name

      expect(sheet.cell(1, 11)).to eq "Case_Owner_User"
      expect(sheet.cell(2, 11)).to eq investigation.owner_user&.name
      expect(sheet.cell(3, 11)).to eq other_user_investigation.owner_user&.name

      expect(sheet.cell(1, 12)).to eq "Source"
      expect(sheet.cell(2, 12)).to eq investigation.creator_user&.name
      expect(sheet.cell(3, 12)).to eq other_user_investigation.creator_user&.name

      expect(sheet.cell(1, 13)).to eq "Complainant_Type"
      expect(sheet.cell(2, 13)).to eq investigation.complainant&.complainant_type
      expect(sheet.cell(3, 13)).to eq other_user_investigation.complainant&.complainant_type

      # TODO: This will be flaky if Faker generates two dupes
      expect(sheet.cell(1, 14)).to eq "Products"
      expect(sheet.cell(2, 14)).to eq "0"
      expect(sheet.cell(3, 14)).to eq "0"

      expect(sheet.cell(1, 15)).to eq "Businesses"
      expect(sheet.cell(2, 15)).to eq "0"
      expect(sheet.cell(3, 15)).to eq "0"

      expect(sheet.cell(1, 16)).to eq "Activities"
      expect(sheet.cell(2, 16)).to eq "1"
      expect(sheet.cell(3, 16)).to eq "1"

      expect(sheet.cell(1, 17)).to eq "Correspondences"
      expect(sheet.cell(2, 17)).to eq "0"
      expect(sheet.cell(3, 17)).to eq "0"

      expect(sheet.cell(1, 18)).to eq "Corrective_Actions"
      expect(sheet.cell(2, 18)).to eq "0"
      expect(sheet.cell(3, 18)).to eq "0"

      expect(sheet.cell(1, 19)).to eq "Tests"
      expect(sheet.cell(2, 19)).to eq "0"
      expect(sheet.cell(3, 19)).to eq "0"

      expect(sheet.cell(1, 20)).to eq "Risk_Assessments"
      expect(sheet.cell(2, 20)).to eq "0"
      expect(sheet.cell(3, 20)).to eq "0"

      expect(sheet.cell(1, 21)).to eq "Date_Created"
      expect(sheet.cell(2, 21)).to eq investigation.created_at&.to_s
      expect(sheet.cell(3, 21)).to eq other_user_investigation.created_at&.to_s

      expect(sheet.cell(1, 22)).to eq "Last_Updated"
      expect(sheet.cell(2, 22)).to eq investigation.updated_at&.to_s
      expect(sheet.cell(3, 22)).to eq other_user_investigation.updated_at&.to_s

      expect(sheet.cell(1, 23)).to eq "Date_Closed"
      expect(sheet.cell(2, 23)).to eq investigation.date_closed&.to_s
      expect(sheet.cell(3, 23)).to eq other_user_investigation.date_closed&.to_s

      expect(sheet.cell(1, 24)).to eq "Date_Validated"
      expect(sheet.cell(2, 24)).to eq investigation.risk_validated_at&.to_s
      expect(sheet.cell(3, 24)).to eq other_user_investigation.risk_validated_at&.to_s

      expect(sheet.cell(1, 25)).to eq "Case_Creator_Team"
      expect(sheet.cell(2, 25)).to eq investigation.creator_user&.team&.name
      expect(sheet.cell(3, 25)).to eq other_user_investigation.creator_user&.team&.name

      expect(sheet.cell(1, 26)).to eq "Notifying_Country"
      expect(sheet.cell(2, 26)).to eq "England"
      expect(sheet.cell(3, 26)).to eq "England"

      expect(sheet.cell(1, 27)).to eq "Reported_as"
      expect(sheet.cell(2, 27)).to eq investigation.reported_reason
      expect(sheet.cell(3, 27)).to eq other_user_investigation.reported_reason
    end
    # rubocop:enable RSpec/MultipleExpectations
    # rubocop:enable RSpec/ExampleLength
  end
end
