require "rails_helper"
require "nokogiri"

RSpec.describe NotificationExport, :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  subject(:notification_export) { described_class.create!(user:, params:) }

  let!(:organisation) { create(:organisation) }
  let!(:team) do
    create(:team, organisation:, team_type: "local_authority", regulator_name: nil, ts_region: "Scotland", ts_acronym: "SCOTSS", ts_area: "Aberdeenshire")
  end
  let!(:other_team) do
    create(:team, organisation:, team_type: "external", regulator_name: "Department of Agriculture, Environment and Rural Affairs (DAERA)", ts_region: nil, ts_acronym: nil, ts_area: nil)
  end
  let!(:user) { create(:user, :activated, :opss_user, organisation:, team:, has_viewed_introduction: true) }
  let!(:other_user_other_team) { create(:user, :activated, :opss_user, name: "other user same team", organisation:, team: other_team) }
  let!(:investigation) do
    create(:allegation, creator: user, reported_reason: "unsafe", hazard_type: "Electromagnetic disturbance", hazard_description: "Much fire", non_compliant_reason: "On fire, lots of fire", risk_level: "serious", user_title: "test allegation title", description: "<p>test allegation</p>").decorate
  end
  let!(:other_team_investigation) { create(:allegation, creator: other_user_other_team, is_private: true, user_title: "Restricted", description: "<p>Restricted</p>").decorate }
  let(:params) { { case_type: "all", created_by: "all", case_status: "open", teams_with_access: "all" } }

  before do
    Investigation.reindex
    Investigation.search_index.refresh
  end

  describe "#export!" do
    let(:result) { notification_export.export! }

    it "attaches the spreadsheet as a file" do
      result
      expect(notification_export.export_file).to be_attached
    end
  end

  describe "#to_spreadsheet" do
    let(:spreadsheet) { notification_export.to_spreadsheet.to_stream }
    let(:exported_data) { Roo::Excelx.new(spreadsheet) }
    let(:sheet) { exported_data.sheet("Notifications") }

    def strip_html_and_preserve_formulas(html)
      Nokogiri::HTML(html).xpath("//text()").map(&:text).join.strip
    end

    def expect_common_cells(sheet, row, investigation)
      expect(sheet.cell(row, 1)).to eq investigation.pretty_id
      expect(sheet.cell(row, 2)).to eq(investigation.is_closed? ? "Closed" : "Open")
      expect(sheet.cell(row, 3)).to eq investigation.type
      expect(sheet.cell(row, 4)).to eq investigation.user_title
      expect(sheet.cell(row, 5)).to eq strip_html_and_preserve_formulas(investigation.description)
      expect(sheet.cell(row, 6)).to eq investigation.categories.presence&.join(", ")
      expect(sheet.cell(row, 7)).to eq investigation.reported_reason
      expect(sheet.cell(row, 8)).to eq investigation.decorate.risk_level_description
      expect(sheet.cell(row, 9)).to eq investigation.hazard_type
      expect(sheet.cell(row, 10)).to eq investigation.hazard_description
      expect(sheet.cell(row, 11)).to eq investigation.non_compliant_reason
    end

    it "exports the common case data", :aggregate_failures do
      expect_common_cells(sheet, 2, investigation)
      expect_common_cells(sheet, 3, other_team_investigation)
    end

    context "when exporting additional case data" do
      it "includes products" do
        expect(sheet.cell(1, 12)).to eq "Products"
        expect(sheet.cell(2, 12)).to eq "0"
      end

      it "includes businesses" do
        expect(sheet.cell(1, 13)).to eq "Businesses"
        expect(sheet.cell(2, 13)).to eq "0"
      end

      it "includes corrective actions" do
        expect(sheet.cell(1, 14)).to eq "Corrective_Actions"
        expect(sheet.cell(2, 14)).to eq "0"
      end

      it "includes tests" do
        expect(sheet.cell(1, 15)).to eq "Tests"
        expect(sheet.cell(2, 15)).to eq "0"
      end

      it "includes risk assessments" do
        expect(sheet.cell(1, 16)).to eq "Risk_Assessments"
        expect(sheet.cell(2, 16)).to eq "0"
      end

      it "includes case owner team" do
        expect(sheet.cell(1, 17)).to eq "Case_Owner_Team"
        expect(sheet.cell(2, 17)).to eq investigation.owner_team&.name
      end

      it "includes case creator team" do
        expect(sheet.cell(1, 18)).to eq "Case_Creator_Team"
        expect(sheet.cell(2, 18)).to eq investigation.creator_user&.team&.name
      end

      it "includes case owner team for other team" do
        expect(sheet.cell(3, 17)).to eq other_team_investigation.owner_team&.name
      end

      it "includes case creator team for other team" do
        expect(sheet.cell(3, 18)).to eq other_team_investigation.creator_user&.team&.name
      end
    end

    context "when exporting case metadata" do
      it "includes notifiers reference" do
        expect(sheet.cell(1, 19)).to eq "Notifiers_Reference"
        expect(sheet.cell(2, 19)).to eq investigation.complainant_reference
      end

      it "includes notifying country" do
        expect(sheet.cell(1, 20)).to eq "Notifying_Country"
        expect(sheet.cell(2, 20)).to eq "England"
      end

      it "includes overseas regulator" do
        expect(sheet.cell(1, 21)).to eq "Overseas_Regulator"
        expect(sheet.cell(2, 21)).to eq "No"
      end

      it "includes country" do
        expect(sheet.cell(1, 22)).to eq "Country"
        expect(sheet.cell(2, 22)).to be_nil
      end

      it "includes trading standards region" do
        expect(sheet.cell(1, 23)).to eq "Trading_Standards_Region"
        expect(sheet.cell(2, 23)).to eq "Scotland"
      end

      it "includes regulator name" do
        expect(sheet.cell(1, 24)).to eq "Regulator_Name"
        expect(sheet.cell(3, 24)).to eq "Department of Agriculture, Environment and Rural Affairs (DAERA)"
      end

      it "includes OPSS internal team" do
        expect(sheet.cell(1, 25)).to eq "OPSS_Internal_Team"
        expect(sheet.cell(2, 25)).to eq "false"
      end

      it "includes date created" do
        expect(sheet.cell(1, 26)).to eq "Date_Created"
        expect(sheet.cell(2, 26)).to eq investigation.created_at&.to_s
      end

      it "includes last updated" do
        expect(sheet.cell(1, 27)).to eq "Last_Updated"
        expect(sheet.cell(2, 27)).to eq investigation.updated_at&.to_s
      end

      it "includes date closed" do
        expect(sheet.cell(1, 28)).to eq "Date_Closed"
        expect(sheet.cell(2, 28)).to eq investigation.date_closed&.to_s
      end

      it "includes date validated" do
        expect(sheet.cell(1, 29)).to eq "Date_Validated"
        expect(sheet.cell(2, 29)).to eq investigation.risk_validated_at&.to_s
      end

      it "includes date submitted_at" do
        expect(sheet.cell(1, 30)).to eq "Date_Submitted"
        expect(sheet.cell(2, 30)).to be_nil
      end

      it "includes notifiers reference for other team" do
        expect(sheet.cell(3, 19)).to eq "Restricted"
      end

      it "includes notifying country for other team" do
        expect(sheet.cell(3, 20)).to eq "England"
      end

      it "includes overseas regulator for other team" do
        expect(sheet.cell(3, 21)).to eq "No"
      end

      it "includes country for other team" do
        expect(sheet.cell(3, 22)).to be_nil
      end

      it "includes trading standards region for other team" do
        expect(sheet.cell(3, 23)).to be_nil
      end

      it "includes OPSS internal team for other team" do
        expect(sheet.cell(3, 25)).to eq "false"
      end

      it "includes date created for other team" do
        expect(sheet.cell(3, 26)).to eq other_team_investigation.created_at&.to_s
      end

      it "includes last updated for other team" do
        expect(sheet.cell(3, 27)).to eq other_team_investigation.updated_at&.to_s
      end

      it "includes date closed for other team" do
        expect(sheet.cell(3, 28)).to eq other_team_investigation.date_closed&.to_s
      end

      it "includes date validated for other team" do
        expect(sheet.cell(3, 29)).to eq other_team_investigation.risk_validated_at ? "Restricted" : nil
      end

      it "includes date submitted_at for other team" do
        expect(sheet.cell(3, 30)).to be_nil
      end
    end

    context "when a created_from_date search parameter is provided" do
      let(:created_from_date) { 1.day.ago }
      let(:params) { { case_type: "all", created_by: "all", case_status: "open", teams_with_access: "all", created_from_date: } }

      let!(:old_case) { create(:allegation, creator: other_user_other_team, is_private: true).decorate }

      before do
        old_case.update!(created_at: 2.days.ago)
        Investigation.search_index.refresh
      end

      it "only exports cases that have been updated since the created_from_date date", :aggregate_failures do
        sheet_ids = sheet.column(1).drop(1)
        expect(sheet_ids).not_to include(old_case.pretty_id)
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

      it "only exports cases that have been updated up to the created_to_date date", :aggregate_failures do
        sheet_ids = sheet.column(1).drop(1)
        expect(sheet_ids).to include(old_case.pretty_id)
        expect(sheet_ids).not_to include(investigation.pretty_id)
        expect(sheet_ids).not_to include(other_team_investigation.pretty_id)
      end
    end

    context "when filtering on reported reason" do
      let(:unsafe_and_non_compliant_notification) { create(:notification, reported_reason: "unsafe_and_non_compliant") }
      let(:safe_and_compliant_notification) { create(:notification, reported_reason: "safe_and_compliant") }
      let(:non_compliant_notification) { create(:notification, reported_reason: "non_compliant") }

      before do
        unsafe_and_non_compliant_notification
        safe_and_compliant_notification
        non_compliant_notification
        Investigation.search_index.refresh
      end

      context "with some reported reasons" do
        let(:params) { { unsafe: true, safe_and_compliant: true } }

        it "only exports the cases with the selected reasons" do
          sheet_ids = sheet.column(1).drop(1)
          expect(sheet_ids).to contain_exactly(investigation.pretty_id, safe_and_compliant_notification.pretty_id)
        end
      end

      context "with no reported reasons" do
        let(:params) { {} }

        it "exports all cases" do
          sheet_ids = sheet.column(1).drop(1)
          expect(sheet_ids).to contain_exactly(investigation.pretty_id, safe_and_compliant_notification.pretty_id, unsafe_and_non_compliant_notification.pretty_id, non_compliant_notification.pretty_id, other_team_investigation.pretty_id)
        end
      end

      context "with all reported reasons" do
        let(:params) { { unsafe: true, safe_and_compliant: true, non_compliant: true, unsafe_and_non_compliant: true } }

        it "exports all cases with a reported reason" do
          sheet_ids = sheet.column(1).drop(1)
          expect(sheet_ids).to contain_exactly(investigation.pretty_id, safe_and_compliant_notification.pretty_id, unsafe_and_non_compliant_notification.pretty_id, non_compliant_notification.pretty_id)
        end
      end
    end

    context "with submitted at date included" do
      let!(:submitted_investigation) { create(:notification, creator: user, state: "submitted", submitted_at: 1.day.ago) }

      before do
        Investigation.search_index.refresh
      end

      it "includes submitted at date for the notification" do
        sheet_ids = sheet.column(1).drop(1)
        expect(sheet_ids).to include(submitted_investigation.pretty_id)
        sheet_ids = sheet.column(30).drop(1)
        expect(sheet_ids).to include(submitted_investigation.submitted_at.strftime("%Y-%m-%d %H:%M:%S %z"))
      end
    end
  end
end
