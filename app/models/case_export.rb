class CaseExport < ApplicationRecord
  include CountriesHelper
  include InvestigationsHelper

  # Helps to manage the database query execution time within the PaaS imposed limits
  FIND_IN_BATCH_SIZE = 1000
  OPENSEARCH_PAGE_SIZE = 10_000

  belongs_to :user
  has_one_attached :export_file

  redacted_export_with :id, :created_at, :updated_at

  def params
    self[:params].deep_symbolize_keys
  end

  def export!
    raise "No notifications to export" unless case_ids.length.positive?

    spreadsheet = to_spreadsheet.to_stream
    self.export_file = { io: spreadsheet, filename: "cases_export.xlsx" }

    raise "No file attached" unless export_file.attached?

    save!
  end

  def to_spreadsheet
    package = Axlsx::Package.new
    sheet = package.workbook.add_worksheet name: "Notifications"

    add_header_row(sheet)

    case_ids.each_slice(FIND_IN_BATCH_SIZE) do |batch_case_ids|
      find_cases(batch_case_ids).each do |investigation|
        sheet.add_row(serialize_case(investigation.decorate), types: :text)
      end
    end

    package
  end

private

  def case_ids
    return @case_ids if @case_ids

    @search = SearchParams.new(params)

    ids = []

    results = search_results

    while results.any?
      ids += results.pluck(:id)

      results = results.scroll
    end

    results.clear_scroll

    ids.sort
  end

  def search_results
    return new_opensearch_for_investigations(OPENSEARCH_PAGE_SIZE, user, scroll: true) if user.can_access_new_search?

    opensearch_for_investigations(OPENSEARCH_PAGE_SIZE, user, scroll: true)
  end

  def activity_counts
    @activity_counts ||= Activity.group(:investigation_id).count
  end

  def business_counts
    @business_counts ||= InvestigationBusiness.unscoped.group(:investigation_id).count
  end

  def product_counts
    @product_counts ||= InvestigationProduct.unscoped.group(:investigation_id).count
  end

  def corrective_action_counts
    @corrective_action_counts ||= CorrectiveAction.group(:investigation_id).count
  end

  def correspondence_counts
    @correspondence_counts ||= Correspondence.group(:investigation_id).count
  end

  def test_counts
    @test_counts ||= Test.group(:investigation_id).count
  end

  def risk_assessment_counts
    @risk_assessment_counts ||= RiskAssessment.group(:investigation_id).count
  end

  def team_mappings
    @team_mappings ||= JSON.load_file!(Rails.root.join("app/assets/team-mappings.json"), object_class: OpenStruct)
  end

  def team_data(team_name)
    # Returns an `OpenStruct` with all nils to avoid having presence checks later
    team_mappings.find { |team| team.team_name == team_name } ||
      OpenStruct.new(team_name: nil, type: nil, regulator_name: nil, ts_region: nil, ts_acronym: nil, ts_area: nil)
  end

  def add_header_row(sheet)
    sheet.add_row %w[ID
                     Status
                     Type
                     Title
                     Description
                     Product_Category
                     Reported_Reason
                     Risk_Level
                     Hazard_Type
                     Unsafe_Reason
                     Non_Compliant_Reason
                     Products
                     Businesses
                     Corrective_Actions
                     Tests
                     Risk_Assessments
                     Case_Owner_Team
                     Case_Creator_Team
                     Notifiers_Reference
                     Notifying_Country
                     Trading_Standards_Region
                     Regulator_Name
                     OPSS_Internal_Team
                     Date_Created
                     Last_Updated
                     Date_Closed
                     Date_Validated]
  end

  def find_cases(ids)
    Investigation
        .includes(:complainant, :products, :owner_team, :owner_user, { creator_user: :team })
        .find(ids)
  end

  def serialize_case(investigation)
    Pundit.policy!(user, investigation).view_protected_details?(user:) || !investigation.is_private? ? non_restricted_data(investigation) : restricted_data(investigation)
  end

  def non_restricted_data(investigation)
    team_data = team_data(investigation.creator_user&.team&.name)

    [
      investigation.pretty_id,
      investigation.is_closed? ? "Closed" : "Open",
      investigation.type,
      investigation.title,
      restrict_data_for_non_opss_user(investigation.object.description),
      investigation.categories.join(", "),
      investigation.reported_reason,
      investigation.risk_level_description,
      investigation.hazard_type,
      investigation.hazard_description,
      investigation.non_compliant_reason,
      product_counts[investigation.id] || 0,
      business_counts[investigation.id] || 0,
      corrective_action_counts[investigation.id] || 0,
      test_counts[investigation.id] || 0,
      risk_assessment_counts[investigation.id] || 0,
      investigation.owner_team&.name,
      investigation.creator_user&.team&.name,
      investigation.complainant_reference,
      country_from_code(investigation.notifying_country, Country.notifying_countries),
      team_data.ts_region,
      team_data.regulator_name,
      restrict_data_for_non_opss_user((team_data.type == "internal")),
      investigation.created_at,
      investigation.updated_at,
      investigation.date_closed,
      restrict_data_for_non_opss_user(investigation.risk_validated_at),
    ]
  end

  def restrict_data_for_non_opss_user(field)
    user.is_opss? ? field : "Restricted"
  end

  def restricted_data(investigation)
    team_data = team_data(investigation.creator_user&.team&.name)

    [
      investigation.pretty_id,
      investigation.is_closed? ? "Closed" : "Open",
      investigation.type,
      "Restricted",
      "Restricted",
      investigation.categories.join(", "),
      investigation.reported_reason,
      investigation.risk_level_description,
      investigation.hazard_type,
      investigation.non_compliant_reason,
      investigation.hazard_description,
      product_counts[investigation.id] || 0,
      business_counts[investigation.id] || 0,
      corrective_action_counts[investigation.id] || 0,
      test_counts[investigation.id] || 0,
      risk_assessment_counts[investigation.id] || 0,
      investigation.owner_team&.name,
      investigation.creator_user&.team&.name,
      "Restricted",
      country_from_code(investigation.notifying_country, Country.notifying_countries),
      team_data.ts_region,
      team_data.regulator_name,
      (team_data.type == "internal"),
      investigation.created_at,
      investigation.updated_at,
      investigation.date_closed,
      investigation.risk_validated_at
    ]
  end
end
