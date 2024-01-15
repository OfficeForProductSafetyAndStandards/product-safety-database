require "rails_helper"

RSpec.describe CaseExport, :with_opensearch, :with_stubbed_notify, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:case_export) do
    described_class.create!(user:, params:)
  end

  let!(:organisation) { create(:organisation) }
  let!(:team) { create(:team, organisation:) }
  let!(:other_team) { create(:team, organisation:) }
  let!(:user) { create(:user, :activated, :opss_user, organisation:, team:, has_viewed_introduction: true) }
  let!(:other_user_other_team) { create(:user, :activated, :opss_user, name: "other user same team", organisation:, team: other_team) }
  let!(:investigation) do
    create(:allegation,
           creator: user,
           reported_reason: "unsafe",
           hazard_type: "Electromagnetic disturbance",
           hazard_description: "Much fire",
           non_compliant_reason: "On fire, lots of fire",
           risk_level: "serious").decorate
  end
  let!(:other_team_investigation) { create(:allegation, creator: other_user_other_team, is_private: true).decorate }
  let(:params) { { case_type: "all", created_by: "all", case_status: "open", teams_with_access: "all" } }
  let(:team_mappings) do
    [
      {
        "team_name": team.name,
        "type": "local_authority",
        "regulator_name": nil,
        "ts_region": "Scotland",
        "ts_acronym": "SCOTSS",
        "ts_area": "Aberdeenshire"
      },
      {
        "team_name": other_team.name,
        "type": "external",
        "regulator_name": "Department of Agriculture, Environment and Rural Affairs (DAERA)",
        "ts_region": nil,
        "ts_acronym": nil,
        "ts_area": nil
      }
    ].to_json
  end

  before do
    Investigation.search_index.refresh
    allow(JSON).to receive(:load_file!).and_return(JSON.parse(team_mappings, object_class: OpenStruct))
  end

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
    let(:sheet) { exported_data.sheet("Notifications") }

    # rubocop:disable RSpec/ExampleLength
    it "exports the case data", :aggregate_failures do
      expect(exported_data.sheets).to eq %w[Notifications]

      expect(sheet.cell(1, 1)).to eq "ID"
      expect(sheet.cell(2, 1)).to eq investigation.pretty_id
      expect(sheet.cell(3, 1)).to eq other_team_investigation.pretty_id

      expect(sheet.cell(1, 2)).to eq "Status"
      expect(sheet.cell(2, 2)).to eq(investigation.is_closed? ? "Closed" : "Open")
      expect(sheet.cell(3, 2)).to eq(other_team_investigation.is_closed? ? "Closed" : "Open")

      expect(sheet.cell(1, 3)).to eq "Type"
      expect(sheet.cell(2, 3)).to eq investigation.type
      expect(sheet.cell(3, 3)).to eq other_team_investigation.type

      expect(sheet.cell(1, 4)).to eq "Title"
      expect(sheet.cell(2, 4)).to eq investigation.title
      expect(sheet.cell(3, 4)).to eq "Restricted"

      expect(sheet.cell(1, 5)).to eq "Description"
      expect(sheet.cell(2, 5)).to eq investigation.object.description
      expect(sheet.cell(3, 5)).to eq "Restricted"

      expect(sheet.cell(1, 6)).to eq "Product_Category"
      expect(sheet.cell(2, 6)).to eq investigation.categories.presence&.join(", ")
      expect(sheet.cell(3, 6)).to eq other_team_investigation.categories.presence&.join(", ")

      expect(sheet.cell(1, 7)).to eq "Reported_Reason"
      expect(sheet.cell(2, 7)).to eq investigation.reported_reason
      expect(sheet.cell(3, 7)).to eq other_team_investigation.reported_reason

      expect(sheet.cell(1, 8)).to eq "Risk_Level"
      expect(sheet.cell(2, 8)).to eq investigation.decorate.risk_level_description
      expect(sheet.cell(3, 8)).to eq other_team_investigation.decorate.risk_level_description

      expect(sheet.cell(1, 9)).to eq "Hazard_Type"
      expect(sheet.cell(2, 9)).to eq investigation.hazard_type
      expect(sheet.cell(3, 9)).to eq other_team_investigation.hazard_type

      expect(sheet.cell(1, 10)).to eq "Unsafe_Reason"
      expect(sheet.cell(2, 10)).to eq investigation.hazard_description
      expect(sheet.cell(3, 10)).to eq other_team_investigation.hazard_description

      expect(sheet.cell(1, 11)).to eq "Non_Compliant_Reason"
      expect(sheet.cell(2, 11)).to eq investigation.non_compliant_reason
      expect(sheet.cell(3, 11)).to eq other_team_investigation.non_compliant_reason

      # TODO: This will be flaky if Faker generates two dupes
      expect(sheet.cell(1, 12)).to eq "Products"
      expect(sheet.cell(2, 12)).to eq "0"
      expect(sheet.cell(3, 12)).to eq "0"

      expect(sheet.cell(1, 13)).to eq "Businesses"
      expect(sheet.cell(2, 13)).to eq "0"
      expect(sheet.cell(3, 13)).to eq "0"

      expect(sheet.cell(1, 14)).to eq "Corrective_Actions"
      expect(sheet.cell(2, 14)).to eq "0"
      expect(sheet.cell(3, 14)).to eq "0"

      expect(sheet.cell(1, 15)).to eq "Tests"
      expect(sheet.cell(2, 15)).to eq "0"
      expect(sheet.cell(3, 15)).to eq "0"

      expect(sheet.cell(1, 16)).to eq "Risk_Assessments"
      expect(sheet.cell(2, 16)).to eq "0"
      expect(sheet.cell(3, 16)).to eq "0"

      expect(sheet.cell(1, 17)).to eq "Case_Owner_Team"
      expect(sheet.cell(2, 17)).to eq investigation.owner_team&.name
      expect(sheet.cell(3, 17)).to eq other_team_investigation.owner_team&.name

      expect(sheet.cell(1, 18)).to eq "Case_Creator_Team"
      expect(sheet.cell(2, 18)).to eq investigation.creator_user&.team&.name
      expect(sheet.cell(3, 18)).to eq other_team_investigation.creator_user&.team&.name

      expect(sheet.cell(1, 19)).to eq "Notifiers_Reference"
      expect(sheet.cell(2, 19)).to eq investigation.complainant_reference
      expect(sheet.cell(3, 19)).to eq "Restricted"

      expect(sheet.cell(1, 20)).to eq "Notifying_Country"
      expect(sheet.cell(2, 20)).to eq "England"
      expect(sheet.cell(3, 20)).to eq "England"

      expect(sheet.cell(1, 21)).to eq "Trading_Standards_Region"
      expect(sheet.cell(2, 21)).to eq "Scotland"
      expect(sheet.cell(3, 21)).to eq nil

      expect(sheet.cell(1, 22)).to eq "Regulator_Name"
      expect(sheet.cell(2, 22)).to eq nil
      expect(sheet.cell(3, 22)).to eq "Department of Agriculture, Environment and Rural Affairs (DAERA)"

      expect(sheet.cell(1, 23)).to eq "OPSS_Internal_Team"
      expect(sheet.cell(2, 23)).to eq "false"
      expect(sheet.cell(3, 23)).to eq "false"

      expect(sheet.cell(1, 24)).to eq "Date_Created"
      expect(sheet.cell(2, 24)).to eq investigation.created_at&.to_s
      expect(sheet.cell(3, 24)).to eq other_team_investigation.created_at&.to_s

      expect(sheet.cell(1, 25)).to eq "Last_Updated"
      expect(sheet.cell(2, 25)).to eq investigation.updated_at&.to_s
      expect(sheet.cell(3, 25)).to eq other_team_investigation.updated_at&.to_s

      expect(sheet.cell(1, 26)).to eq "Date_Closed"
      expect(sheet.cell(2, 26)).to eq investigation.date_closed&.to_s
      expect(sheet.cell(3, 26)).to eq other_team_investigation.date_closed&.to_s

      expect(sheet.cell(1, 27)).to eq "Date_Validated"
      expect(sheet.cell(2, 27)).to eq investigation.risk_validated_at&.to_s
      expect(sheet.cell(3, 27)).to eq other_team_investigation.risk_validated_at&.to_s
    end
    # rubocop:enable RSpec/ExampleLength

    context "when filtering on case type" do
      let!(:notification) { create(:notification) }
      let!(:allegation) { create(:allegation) }
      let!(:project) { create(:project) }
      let!(:enquiry) { create(:enquiry) }

      let(:params) { { case_type:, created_by: "all", case_status: "open", teams_with_access: "all" } }

      before { Investigation.search_index.refresh }

      context "with the new search" do
        before { user.roles.create(name: "use_new_search") }

        context "with all cases" do
          let(:params) { { allegation: true, project: true, enquiry: true, notification: true } }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports all case types", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [investigation.pretty_id, other_team_investigation.pretty_id, notification.pretty_id, allegation.pretty_id, project.pretty_id, enquiry.pretty_id]
          end
        end

        context "with allegations" do
          let(:params) { { allegation: true } }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports allegations", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [investigation.pretty_id, other_team_investigation.pretty_id, allegation.pretty_id]
          end
        end

        context "with enquiries" do
          let(:params) { { enquiry: true } }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports enquiries", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [enquiry.pretty_id]
          end
        end

        context "with projects" do
          let(:params) { { project: true } }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports projects", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [project.pretty_id]
          end
        end

        context "with notifications" do
          let(:params) { { notification: true } }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports notifications", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [notification.pretty_id]
          end
        end

        context "with more results than the upper search limit on notifications" do
          before do
            create_list(:notification, 3)
            Investigation.search_index.refresh
          end

          let(:params) { { notification: true } }

          it "exports all notifications" do
            stub_const("CaseExport::OPENSEARCH_PAGE_SIZE", 2)
            expect(sheet.last_row).to eq 5
          end
        end
      end

      context "with the old search" do
        context "with all cases" do
          let(:case_type) { "all" }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports all case types", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [investigation.pretty_id, other_team_investigation.pretty_id, notification.pretty_id, allegation.pretty_id, project.pretty_id, enquiry.pretty_id]
          end
        end

        context "with allegations" do
          let(:case_type) { "allegation" }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports allegations", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [investigation.pretty_id, other_team_investigation.pretty_id, allegation.pretty_id]
          end
        end

        context "with enquiries" do
          let(:case_type) { "enquiry" }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports enquiries", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [enquiry.pretty_id]
          end
        end

        context "with projects" do
          let(:case_type) { "project" }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports projects", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [project.pretty_id]
          end
        end

        context "with notifications" do
          let(:case_type) { "notification" }

          it "exports the case data", :aggregate_failures do
            expect(exported_data.sheets).to eq %w[Notifications]
          end

          it "only exports notifications", :aggregate_failures do
            sheet_ids = sheet.column(1).drop(1)
            expect(sheet_ids).to match_array [notification.pretty_id]
          end
        end
      end
    end

    context "when a created_from_date search parameter is provided" do
      let(:created_from_date) { 1.day.ago }
      let(:params) { { case_type: "all", created_by: "all", case_status: "open", teams_with_access: "all", created_from_date: } }

      let!(:old_case) { create(:allegation, creator: other_user_other_team, is_private: true).decorate }

      before do
        old_case.update!(created_at: 2.days.ago)
      end

      it "exports the case data", :aggregate_failures do
        expect(exported_data.sheets).to eq %w[Notifications]
      end

      it "only exports cases that have been updated since the created_from_date date", :aggregate_failures do
        expect(sheet.cell(1, 1)).to eq "ID"
        expect(sheet.cell(2, 1)).to eq investigation.pretty_id
        expect(sheet.cell(3, 1)).to eq other_team_investigation.pretty_id
        expect(sheet.cell(4, 1)).not_to eq old_case.pretty_id
      end
    end

    context "when a created_to_date search parameter is provided" do
      let(:created_to_date) { 1.day.ago }
      let(:params) { { case_type: "all", created_by: "all", case_status: "open", teams_with_access: "all", created_to_date: } }

      let!(:old_case) { create(:allegation, creator: other_user_other_team, is_private: true).decorate }

      before do
        old_case.update!(created_at: 2.days.ago)
        Investigation.search_index.refresh
      end

      it "exports the case data", :aggregate_failures do
        expect(exported_data.sheets).to eq %w[Notifications]
      end

      it "only exports cases that have been updated up to the created_to_date date", :aggregate_failures do
        expect(sheet.cell(1, 1)).to eq "ID"
        expect(sheet.cell(2, 1)).to eq old_case.pretty_id
        expect(sheet.cell(3, 1)).not_to eq investigation.pretty_id
        expect(sheet.cell(4, 1)).not_to eq other_team_investigation.pretty_id
      end
    end

    context "when filtering on reported reason" do
      let(:unsafe_and_non_compliant_notification) { create(:notification, reported_reason: "unsafe_and_non_compliant") }
      let(:safe_and_compliant_notification) { create(:notification, reported_reason: "safe_and_compliant") }
      let(:non_compliant_notification) { create(:notification, reported_reason: "non_compliant") }

      before do
        user.roles.create!(name: "use_new_search")
        unsafe_and_non_compliant_notification
        safe_and_compliant_notification
        non_compliant_notification
        Investigation.search_index.refresh
      end

      context "with some reported reasons" do
        let(:params) { { unsafe: true, safe_and_compliant: true } }

        it "exports the case data", :aggregate_failures do
          expect(exported_data.sheets).to eq %w[Notifications]
        end

        it "only exports the cases with the selected reasons" do
          sheet_ids = sheet.column(1).drop(1)
          expect(sheet_ids).to match_array [investigation.pretty_id, safe_and_compliant_notification.pretty_id]
        end
      end

      context "with no reported reasons" do
        let(:params) { {} }

        it "exports the case data", :aggregate_failures do
          expect(exported_data.sheets).to eq %w[Notifications]
        end

        it "exports all cases" do
          sheet_ids = sheet.column(1).drop(1)
          expect(sheet_ids).to match_array [investigation.pretty_id, safe_and_compliant_notification.pretty_id, unsafe_and_non_compliant_notification.pretty_id, non_compliant_notification.pretty_id, other_team_investigation.pretty_id]
        end
      end

      context "with all reported reasons" do
        let(:params) { { unsafe: true, safe_and_compliant: true, non_compliant: true, unsafe_and_non_compliant: true } }

        it "exports the case data", :aggregate_failures do
          expect(exported_data.sheets).to eq %w[Notifications]
        end

        it "exports all cases with a reported reason" do
          sheet_ids = sheet.column(1).drop(1)
          expect(sheet_ids).to match_array [investigation.pretty_id, safe_and_compliant_notification.pretty_id, unsafe_and_non_compliant_notification.pretty_id, non_compliant_notification.pretty_id]
        end
      end
    end
  end
end
