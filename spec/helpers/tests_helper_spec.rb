require "rails_helper"

RSpec.describe TestsHelper, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  let(:test_result) { create(:test_result) }

  describe "#test_result_summary_rows" do
    context "when the test result does not have an attachment" do
      before { test_result.document.detach }

      it "does not show the Attachment description row" do
        expect(helper.test_result_summary_rows(test_result))
          .not_to include(a_hash_including(key: { text: "Attachment description" }))
      end
    end
  end
end
