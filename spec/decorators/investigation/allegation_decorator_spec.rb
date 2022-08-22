require "rails_helper"

RSpec.describe Investigation::AllegationDecorator, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:decorated_allegation) { allegation.decorate }

  let(:allegation) { create(:allegation, :reported_unsafe, user_title: "inputted user_title") }

  describe "#display_product_summary_list?" do
    it { is_expected.to be_display_product_summary_list }
  end

  describe "#title" do
    context "when investigation has a user_title" do
      it "shows user_title" do
        expect(decorated_allegation.title).to eq(allegation.user_title)
      end
    end

    context "when investigation does not have a user_title" do
      before do
        allegation.update(user_title: nil)
      end

      context "when products are present" do
        context "with one product" do
          before do
            allegation.products.build attributes_for(:product, name: "iPhone XS MAX", subcategory: "phone")
          end

          context "when no reason was reported" do
            let(:allegation) { create(:allegation, user_title: nil) }

            it "produces the correct title" do
              expect(decorated_allegation.title).to eq("iPhone XS MAX, phone")
            end
          end

          context "when reported safe" do
            let(:allegation) { create(:allegation, :reported_safe, user_title: nil) }

            it "produces the correct title" do
              expect(decorated_allegation.title).to eq("iPhone XS MAX, phone – product safe and compliant")
            end
          end

          context "when reported unsafe and non-compliant" do
            let(:allegation) { create(:allegation, :reported_unsafe_and_non_compliant, user_title: nil) }

            it "produces the correct title" do
              expect(decorated_allegation.title).to eq("iPhone XS MAX, phone – #{allegation.hazard_type.downcase} hazard")
            end
          end
        end

        context "with two products" do
          before { allegation.products.build attributes_for(:product, name: "iPhone XS MAX", subcategory: "phone") }

          context "when reported safe" do
            let(:allegation) { create(:allegation, :reported_safe, user_title: nil) }

            before { allegation.products.build attributes_for(:product, name: "iPhone 3", subcategory: "phone") }

            it "produces the correct title" do
              expect(decorated_allegation.title).to eq("2 products, phone – products safe and compliant")
            end
          end

          context "when reported unsafe" do
            let(:allegation) { create(:allegation, :reported_unsafe, user_title: nil) }

            # rubocop:disable RSpec/NestedGroups
            context "with two common values" do
              before { allegation.products.build attributes_for(:product, name: "iPhone 3", subcategory: "phone") }

              it "produces the correct title" do
                expect(decorated_allegation.title).to eq("2 products, phone – #{allegation.hazard_type.downcase} hazard")
              end
            end

            context "with no common values" do
              before { allegation.products.build attributes_for(:product, name: "chromcast", subcategory: "tv dongle") }

              it "produces the correct title" do
                expect(decorated_allegation.title).to eq("2 products – #{allegation.hazard_type.downcase} hazard")
              end
            end
            # rubocop:enable RSpec/NestedGroups
          end
        end
      end

      context "when no products are present on the case" do
        before { allegation.product_category = "Alarms" }

        context "when reporting unsafe" do
          it "has the correct title" do
            expect(decorated_allegation.title).to eq("Alarms – #{allegation.hazard_type.downcase} hazard (no product specified)")
          end
        end

        context "when reporting safe" do
          let(:allegation) { create(:allegation, :reported_safe, user_title: nil) }

          it "has the correct title" do
            expect(decorated_allegation.title).to eq("Alarms - safe and compliant")
          end
        end
      end
    end
  end
end
