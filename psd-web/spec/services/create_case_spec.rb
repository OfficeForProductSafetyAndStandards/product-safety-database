require "rails_helper"

RSpec.describe CreateCase, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  let(:investigation) { build(:enquiry, creator: user) }
  let(:user) { create(:user) }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation: investigation) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(investigation: investigation, user: user) }

      it "returns success" do
        expect(result).to be_success
      end

      context "when there is no source already on the investigation" do
        before { investigation.source = nil }

        it "sets the user source" do
          result
          expect(investigation.reload.source.user).to eq(user)
        end
      end

      context "when there is no owner already on the investigation" do
        before { investigation.owner = nil }

        it "sets the owner to the user" do
          result
          expect(investigation.reload.owner).to eq(user)
        end
      end

      it "generates a pretty_id" do
        result
        expect(investigation.reload.pretty_id).to be_a(String)
      end

      it "creates an audit activity for case created", :aggregate_failures do
        result
        activity = investigation.reload.activities.first
        expect(activity).to be_a(AuditActivity::Investigation::AddEnquiry)
        expect(activity.source.user).to eq(user)
        expect(activity.metadata).to eq(AuditActivity::Investigation::AddEnquiry.build_metadata(investigation).deep_stringify_keys)
      end

      context "when there are products added to the case" do
        let(:investigation) { build(:allegation, products: [product], creator: user) }
        let(:product) { create(:product_washing_machine) }

        it "creates an audit activity for product added", :aggregate_failures do
          result
          activity = investigation.reload.activities.first
          expect(activity).to be_a(AuditActivity::Product::Add)
          expect(activity.source.user).to eq(user)
          expect(activity.product_id).to eq(product.id)
          expect(activity.title).to eq(product.name)
        end
      end

      it "sends a notification email to the case creator" do
        expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_created).with(
          kind_of(String),
          user.name,
          user.email,
          "test enquiry title",
          "enquiry"
        )
      end
    end
  end
end
