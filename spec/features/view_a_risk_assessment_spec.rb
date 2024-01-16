RSpec.feature "View a risk assessment on a notification", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:risk_assessment_file_path) { Rails.root.join "test/fixtures/files/new_risk_assessment.txt" }
  let(:risk_assessment_file) { Rack::Test::UploadedFile.new(risk_assessment_file_path) }
  let(:user) { create(:user, :activated, name: "Joe Bloggs") }

  let(:teddy_bear) { create(:product, name: "Teddy Bear") }
  let(:doll) { create(:product, name: "Doll") }

  let!(:doll_investigation_product) { create(:investigation_product, investigation:, product: doll) } # rubocop:disable RSpec/LetSetup
  let!(:teddy_bear_investigation_product) { create(:investigation_product, investigation:, product: teddy_bear) }

  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let!(:risk_assessment) do
    create(:risk_assessment,
           investigation:,
           assessed_on: Date.parse("2020-01-02"),
           assessed_by_team: team,
           risk_level: :serious,
           investigation_products: [teddy_bear_investigation_product],
           risk_assessment_file:)
  end

  context "when the user has created the investigation" do
    let(:investigation) do
      create(:allegation,
             creator: user,
             risk_level: :serious)
    end

    scenario "Viewing a risk assessment" do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}"

      click_link "Supporting information (1)"
      click_link "Serious risk: Teddy Bear"

      expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)
      expect_to_have_notification_breadcrumbs
    end
  end

  context "when the user has not created the investigation" do
    let(:investigation) do
      create(:allegation,
             creator: second_user,
             risk_level: :serious)
    end
    let(:second_user) { create(:user, :activated, name: "John Doe") }

    scenario "Viewing a risk assessment" do
      sign_in(user)
      visit "/cases/#{investigation.pretty_id}"

      click_link "Supporting information (1)"
      click_link "Serious risk: Teddy Bear"

      expect_to_be_on_risk_assessement_for_a_case_page(case_id: investigation.pretty_id, risk_assessment_id: risk_assessment.id)
      expect_to_have_notification_breadcrumbs
    end
  end
end
