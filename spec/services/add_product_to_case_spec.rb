require "rails_helper"

RSpec.describe AddProductToCase, :with_test_queue_adapter do
  let(:user) { create(:user, :opss_user) }
  let(:investigation) { create(:allegation, creator: user) }
  let(:product) { create(:product) }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation:, product:) }

      it "returns a failure", :aggregate_failures do
        expect(result).to be_failure
        expect(result.error).to eq("No user supplied")
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user:, product:) }

      it "returns a failure", :aggregate_failures do
        expect(result).to be_failure
        expect(result.error).to eq("No investigation supplied")
      end
    end

    context "with no product parameter" do
      let(:result) { described_class.call(user:, investigation:) }

      it "returns a failure", :aggregate_failures do
        expect(result).to be_failure
        expect(result.error).to eq("No product supplied")
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Case updated"
      end

      def expected_email_body(name)
        "Product was added to the case by #{name}."
      end

      let(:result) { described_class.call(user:, investigation:, product:) }

      it "returns success" do
        expect(result).to be_success
      end

      it "adds the product to the case" do
        result
        expect(investigation.products).to include(product)
      end

      it "sets the product's owning team to be the user's team" do
        expect(result.product.owning_team).to eq(user.team)
      end

      it "creates an audit activity", :aggregate_failures do
        result
        activity = investigation.reload.activities.first
        expect(activity).to be_a(AuditActivity::Product::Add)
        expect(activity.added_by_user).to eq(user)
        expect(activity.investigation_product).to eq(investigation.investigation_products.first)
        expect(activity.title(nil)).to eq(product.name)
      end

      it_behaves_like "a service which notifies the case owner"

      context "with a product owned by someone else" do
        let(:product) { create(:product, owning_team: create(:team)) }

        it "does not change the owning team", :aggregate_failures do
          expect(result.product.owning_team).not_to eq(nil)
          expect(result.product.owning_team).not_to eq(user.team)
        end
      end

      context "with a product that is already added to the case" do
        context "when an existing investigation_product exists but does not share the same investigation_closed_at" do
          before do
            investigation.products << product
            investigation.investigation_products.first.update!(investigation_closed_at: Time.current)
          end

          it "returns a success" do
            expect(result).to be_success
          end

          it "adds the product" do
            result
            expect(investigation.investigation_products.count).to eq(2)
          end
        end

        context "when an existing investigation_product exists which shares the same investigation_closed_at" do
          before do
            investigation.products << product
          end

          it "returns a failure", :aggregate_failures do
            expect(result).to be_failure
            expect(result.error).to eq("The product is already linked to the case")
          end

          it "does not add the product twice" do
            result
            expect(investigation.investigation_products.count).to eq(1)
          end
        end
      end
    end
  end
end
