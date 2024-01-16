RSpec.describe Investigations::TestResultsController, type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine) }
  let(:investigation) { create(:allegation, products: [product], creator: user) }

  let(:params) do
    {
      product_id: product.id,
      legislation: Rails.application.config.legislation_constants["legislation"].sample,
      standards_product_was_tested_against: "EN71",
      result: :passed,
      date: { day: "1", month: "2", year: "2020" },
      document_form: {
        file: Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt"),
        description: Faker::Hipster.sentence
      }
    }
  end

  before { sign_in user }

  context "when the AddTestResultToInvestigation.call is not successful" do
    let(:service) { double(AddTestResultToInvestigation, "success?": false) } # rubocop:disable RSpec/VerifiedDoubles

    before { allow(AddTestResultToInvestigation).to receive(:call).and_return(service) }

    it "re-renders the form", :aggregate_failures do
      expect {
        post investigation_test_results_path(investigation.pretty_id), params: { test_result: params }
      }.not_to change(Test::Result, :count)

      expect(response).to render_template(:new)
    end
  end
end
