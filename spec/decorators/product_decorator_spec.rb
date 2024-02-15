require "rails_helper"

RSpec.describe ProductDecorator, :with_stubbed_opensearch do
  subject(:decorated_product) { product.decorate }

  let(:product) { build(:product, authenticity: "unsure") }

  describe "#pretty_description" do
    specify { expect(decorated_product.pretty_description).to eq("Product: #{product.name}") }
  end

  describe "#details_list" do
    include CountriesHelper

    let(:details_list) { decorated_product.details_list }

    context "when displaying the product summary" do
      it "displays the Brand name" do
        expect(details_list).to summarise("Brand name", text: product.brand)
      end

      it "displays the Product name" do
        expect(details_list).to summarise("Product name", text: product.name)
      end

      it "displays the Category" do
        expect(details_list).to summarise("Category", text: product.category)
      end

      it "displays the Subcategory" do
        expect(details_list).to summarise("Subcategory", text: product.subcategory)
      end

      it "displays the Barcode" do
        expect(details_list).to summarise("Barcode", text: product.barcode)
      end

      it "displays the Description" do
        expect(details_list).to summarise("Description", text: product.description)
      end

      it "displays the Webpage" do
        expect(details_list).to summarise("Webpage", text: product.webpage)
      end

      it "displays the Country of origin" do
        expect(details_list).to summarise("Country of origin", text: country_from_code(product.country_of_origin))
      end

      it "displays product Authenticity" do
        expect(details_list).to summarise("Counterfeit", text: "Unsure")
      end

      it "displays the Product marking" do
        expect(details_list).to summarise("Product marking", text: decorated_product.markings)
      end

      it "displays the Other product identifiers" do
        expect(details_list).to summarise("Other product identifiers", text: product.product_code)
      end
    end
  end

  describe "#description" do
    include_examples "a formated text", :product, :description
    include_examples "with a blank description", :product, :decorated_product
  end

  describe "#unformatted_description" do
    include_examples "with a blank description", :product, :decorated_product

    context "when the product has a description" do
      let(:product) { build(:product, description: "A description") }

      it "returns the unformatted description" do
        expect(decorated_product.unformatted_description).to eq("A description")
      end

      it "returns the formatted description as HTML" do
        expect(decorated_product.description).to eq("<p>A description</p>")
      end
    end
  end

  describe "#subcategory_and_category_label" do
    context "when both the Product sub-category and and category are present" do
      it "combines Product sub-category and product category" do
        expect(decorated_product.subcategory_and_category_label)
          .to eq("#{product.subcategory} (#{product.category.downcase})")
      end
    end

    context "when only the category is present" do
      before { product.subcategory = nil }

      it "returns only the product category" do
        expect(decorated_product.subcategory_and_category_label)
          .to eq(product.category)
      end
    end

    context "when only the Product subcategory is present" do
      before { product.category = nil }

      it "returns only the Product subcategory" do
        expect(decorated_product.subcategory_and_category_label)
          .to eq(product.subcategory)
      end
    end
  end

  describe "#markings" do
    context "when has_markings is nil" do
      before { product.has_markings = nil }

      it "returns a String" do
        expect(decorated_product.markings).to eq("Not provided")
      end
    end

    context "when has_markings == markings_unknown" do
      before { product.has_markings = "markings_unknown" }

      it "returns a String" do
        expect(decorated_product.markings).to eq("Unknown")
      end
    end

    context "when has_markings == markings_no" do
      before { product.has_markings = "markings_no" }

      it "returns a String" do
        expect(decorated_product.markings).to eq("None")
      end
    end

    context "when has_markings == markings_yes" do
      before do
        product.has_markings = "markings_yes"
        product.markings = %w[UKCA UKNI CE]
      end

      it "joins into a single String" do
        expect(decorated_product.markings).to eq("UKCA, UKNI, CE")
      end
    end

    context "when has_markings and markings are nil" do
      before do
        product.has_markings = nil
        product.markings = nil
      end

      it "returns a String" do
        expect(decorated_product.markings).to eq("Not provided")
      end
    end
  end

  describe "#owning_team_link" do
    let(:user) { create(:user) }
    let(:product) { create(:product, owning_team:) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "when the product is not owned" do
      let(:owning_team) { nil }

      it "returns 'No owner'" do
        expect(decorated_product.owning_team_link).to eq("No owner")
      end
    end

    context "when the product is owned by the user's team" do
      let(:owning_team) { user.team }

      it "returns 'Your team is the product record owner'" do
        expect(decorated_product.owning_team_link).to eq("Your team is the product record owner")
      end
    end

    context "when the product is owned by another team" do
      let(:owning_team) { build(:team, name: "Other Team") }

      it "returns a link to the other team's contact details" do
        expect(decorated_product.owning_team_link).to have_link("Other Team", href: owner_product_path(product))
      end
    end
  end

  describe "#unique_investigations_except", :with_stubbed_mailer do
    context "when product is linked to multiple investigations" do
      let(:product) { create(:product) }

      before do
        create(:allegation, user_title: "investigation 1", products: [product])
        create(:allegation, user_title: "investigation 2", products: [product])
        create(:allegation, user_title: "investigation 3", products: [product])
        create(:allegation, user_title: "investigation 4", products: [product])
      end

      it "returns each unique linked investigation excluding the investigation that the is currently being viewed" do
        investigation = Investigation.find_by(user_title: "investigation 1")
        unique_cases = decorated_product.unique_cases_except(investigation)

        expect(unique_cases.map(&:user_title)).to eq ["investigation 4", "investigation 3", "investigation 2"]
      end
    end
  end
end
