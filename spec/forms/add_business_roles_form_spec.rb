require "rails_helper"

RSpec.describe AddBusinessRolesForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(add_business_roles_form_params) }

  let(:add_business_roles_form_params) { { roles:, online_marketplace_id:, new_online_marketplace_name:, authorised_representative_choice: } }
  let(:roles) { Business::BUSINESS_TYPES - %w[online_marketplace authorised_representative] }
  let(:online_marketplace_id) { nil }
  let(:new_online_marketplace_name) { nil }
  let(:authorised_representative_choice) { nil }
  let(:online_marketplace) { create(:online_marketplace) }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when authorised_representative is selected" do
      let(:roles) { %w[authorised_representative] }

      context "when a valid authorised_representative_choice is selected" do
        let(:authorised_representative_choice) { "uk_authorised_representative" }

        it "is valid" do
          expect(form).to be_valid
        end
      end

      context "when an invalid authorised_representative_choice is selected" do
        let(:authorised_representative_choice) { "non_authorised_representative" }

        it "is not valid" do
          expect(form).not_to be_valid
        end
      end
    end

    context "when online_marketplace is included" do
      context "when it is the sole business type" do
        let(:roles) { %w[online_marketplace] }

        context "when no online_marketplace_id or new_online_marketplace_name is provided" do
          it "is not valid" do
            expect(form).not_to be_valid
          end
        end

        context "when an existing online marketplace id is provided" do
          let(:online_marketplace_id) { online_marketplace.id }

          it "is valid" do
            expect(form).to be_valid
          end
        end

        context "when an existing online marketplace id and new online marketplace name are provided" do
          let(:online_marketplace_id) { online_marketplace.id }
          let(:new_online_marketplace_name) { "New online marketplace" }

          it "is not valid" do
            expect(form).not_to be_valid
          end
        end

        context "when a new online marketplace name is provided" do
          let(:new_online_marketplace_name) { "New online marketplace" }

          it "is valid" do
            expect(form).to be_valid
          end
        end
      end

      context "when it is one of many business types" do
        let(:roles) { %w[online_marketplace retailer] }

        it "is not valid" do
          expect(form).not_to be_valid
        end
      end
    end

    context "when only allowed business types are included" do
      let(:roles) { %w[bad_type] }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
