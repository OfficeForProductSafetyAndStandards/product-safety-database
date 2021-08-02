class CaseExport < ApplicationRecord
  include CountriesHelper

  has_one_attached :export_file

  def export(cases)
    activity_counts = Activity.group(:investigation_id).count
    business_counts = InvestigationBusiness.unscoped.group(:investigation_id).count
    product_counts = InvestigationProduct.unscoped.group(:investigation_id).count
    corrective_action_counts = CorrectiveAction.group(:investigation_id).count
    correspondence_counts = Correspondence.group(:investigation_id).count
    test_counts = Test.group(:investigation_id).count
    risk_assessment_counts = RiskAssessment.group(:investigation_id).count

    Axlsx::Package.new do |p|
      book = p.workbook

      add_cases_worksheet(book, cases, product_counts, business_counts, activity_counts,
                          correspondence_counts, corrective_action_counts, test_counts,
                          risk_assessment_counts)

      Tempfile.create("cases_export", Rails.root.join("tmp")) do |f|
        p.serialize(f)
        export_file.attach(io: f, filename: "cases_export.xlsx")
      end
    end
  end

private

  def add_cases_worksheet(book, cases, product_counts, business_counts, activity_counts,
                          correspondence_counts, corrective_action_counts, test_counts,
                          risk_assessment_counts)
    book.add_worksheet name: "Cases" do |sheet_investigations|
      sheet_investigations.add_row %w[ID
                                      Status
                                      Title
                                      Type
                                      Description
                                      Product_Category
                                      Hazard_Type
                                      Coronavirus_Related
                                      Risk_Level
                                      Case_Owner_Team
                                      Case_Owner_User
                                      Source
                                      Complainant_Type
                                      Products
                                      Businesses
                                      Activities
                                      Correspondences
                                      Corrective_Actions
                                      Tests
                                      Risk_Assessments
                                      Date_Created
                                      Last_Updated
                                      Date_Closed
                                      Date_Validated
                                      Case_Creator_Team
                                      Notifying_Country
                                      Reported_as]
      cases.each do |investigation|
        sheet_investigations.add_row [
          investigation.pretty_id,
          investigation.is_closed? ? "Closed" : "Open",
          investigation.title,
          investigation.type,
          investigation.description,
          investigation.categories.join(", "),
          investigation.hazard_type,
          investigation.coronavirus_related?,
          investigation.decorate.risk_level_description,
          investigation.owner_team&.name,
          investigation.owner_user&.name,
          investigation.creator_user&.name,
          investigation.complainant&.complainant_type,
          product_counts[investigation.id] || 0,
          business_counts[investigation.id] || 0,
          activity_counts[investigation.id] || 0,
          correspondence_counts[investigation.id] || 0,
          corrective_action_counts[investigation.id] || 0,
          test_counts[investigation.id] || 0,
          risk_assessment_counts[investigation.id] || 0,
          investigation.created_at,
          investigation.updated_at,
          investigation.date_closed,
          investigation.risk_validated_at,
          investigation.creator_user&.team&.name,
          country_from_code(investigation.notifying_country, Country.notifying_countries),
          investigation.reported_reason
        ], types: :text
      end
    end
  end
end
