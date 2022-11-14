require "rails_helper"

RSpec.describe RemoveProductFromCase, :with_test_queue_adapter do
  subject(:result) { described_class.call(investigation:, investigation_product:, user:, reason:) }

  let(:investigation) { create(:allegation, products: [product], creator:) }
  let(:product)       { create(:product_washing_machine, owning_team: creator.team) }
  let(:investigation_product) { investigation.investigation_products.first }
  let(:reason)        { Faker::Hipster.sentence }
  let(:user)          { create(:user, :opss_user) }
  let(:creator)       { user }
  let(:owner)         { user }

  describe ".call" do
    context "with stubbed opensearch", :with_stubbed_opensearch do
      context "with no parameters" do
        let(:result) { described_class.call }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      context "with no investigation parameter" do
        let(:result) { described_class.call(product:, user:) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      context "with no product parameter" do
        let(:result) { described_class.call(investigation:, user:) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      context "with no user parameter" do
        let(:result) { described_class.call(investigation:, product:) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      context "with required parameters" do
        context "if case has not been closed while product was linked to it" do
          def expected_email_subject
            "Allegation updated"
          end

          def expected_email_body(name)
            "Product was removed from the allegation by #{name}."
          end

          it "returns success" do
            expect(result).to be_success
          end

          it "removes the product from the case" do
            result
            expect(investigation.reload.products).not_to include(product)
          end

          it "creates an audit activity", :aggregate_failures do
            result
            activity = investigation.reload.activities.find_by!(type: AuditActivity::Product::Destroy.name)
            expect(activity).to have_attributes(title: nil, body: nil, product_id: product.id, metadata: { "reason" => reason, "product" => JSON.parse(product.attributes.to_json) })
            expect(activity.added_by_user).to eq(user)
          end

          it_behaves_like "a service which notifies the case owner"
        end

        context "if case has been closed while product was linked to it" do
          before do
            ChangeCaseStatus.call!(investigation: investigation, new_status: "closed", user: user)
          end

          it "returns failure" do
            result = described_class.call(investigation: investigation.reload, investigation_product: investigation_product.reload, user:, reason:)
            expect(result).to be_failure
          end

          it "does not remove the product from the case" do
            described_class.call(investigation: investigation.reload, investigation_product: investigation_product.reload, user:, reason:)
            expect(investigation.reload.products).to include(product)
          end
        end

        it "creates an audit activity", :aggregate_failures do
          result
          activity = investigation.reload.activities.find_by!(type: AuditActivity::Product::Destroy.name)
          expect(activity).to have_attributes(title: nil, body: nil, product_id: product.id, metadata: { "reason" => reason, "product" => JSON.parse(product.attributes.to_json) })
          expect(activity.added_by_user).to eq(user)
        end

        it "sets the product to unowned" do
          result
          expect(product.reload.owning_team).to eq(nil)
        end

        it_behaves_like "a service which notifies the case owner"

        context "when the product is owned by another team" do
          let(:product) { create(:product_washing_machine, owning_team: create(:team)) }

          it "does not change the product's ownership", :aggregate_failures do
            result
            product.reload
            expect(product.owning_team).not_to eq(investigation.owner_team)
            expect(product.owning_team).not_to eq(nil)
          end
        end

        context "when the product is linked to another of its owning team's cases" do
          before do
            create :allegation, products: [product], creator:
          end

          it "does not change the product's ownership" do
            result
            expect(product.reload.owning_team).to eq(investigation.owner_team)
          end
        end
      end
    end

    context "when searching for product once removed from the case", :with_opensearch do
      let(:records) { Product.full_search(OpensearchQuery.new(product.name, {}, {})).records }

      before do
        product
        Product.import(refresh: :wait_for)
      end

      it "the product should remain searchable" do
        result

        expect(records.to_a).to include(product)
      end
    end
  end
end
