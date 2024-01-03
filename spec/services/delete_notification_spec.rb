require "rails_helper"

RSpec.describe DeleteNotification, :with_stubbed_mailer, :with_stubbed_opensearch do
  describe ".call" do
    context "with no parameters" do
      subject(:delete_call) { described_class.call }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "No investigation supplied"
      end
    end

    context "when given an investigation that has products" do
      subject(:delete_call) { described_class.call(investigation:, deleted_by:) }

      let(:deleted_by) { create(:user) }
      let(:investigation) { create(:allegation, :with_products) }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "Cannot delete investigation with products"
      end
    end

    context "when given an investigation without products" do
      subject(:delete_call) { described_class.call(investigation:, deleted_by:) }

      let(:deleted_by)        { create(:user) }
      let!(:investigation) { create(:allegation) }

      it "succeeds" do
        expect(delete_call).to be_a_success
      end

      it "sets the investigation deleted timestamp" do
        freeze_time do
          expect {
            delete_call
            investigation.reload
          }.to change(investigation, :deleted_at).from(nil).to(Time.zone.now)
        end
      end

      it "changes investigation deleted_by" do
        expect {
          delete_call
          investigation.reload
        }.to change(investigation, :deleted_by).from(nil).to(deleted_by.id)
      end

      it "does not send notifications to the user or the team" do
        expect { delete_call }.not_to change(delivered_emails, :count)
      end
    end
  end
end
