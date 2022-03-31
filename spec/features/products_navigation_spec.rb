require "rails_helper"

RSpec.feature "Searching products", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: team }

  before do
    sign_in user
    visit "/products"
  end

  context "when there are no products" do
    context "when the user is on the your products page" do
      before do
        click_on "Your products"
      end

      it "explains that the user has no products" do
        expect(page).to have_content "There are 0 products linked to open cases where you are the case owner."
      end

      it "highlights the your products tab" do
        expect(highlighted_tab).to eq "Your products"
      end
    end

    context "when the user is on the team products page" do
      before do
        click_on "All products"
        click_on "Team products"
      end

      it "explains that the team has no products" do
        visit "/products"
        click_on "Team products"
        expect(page).to have_content "There are 0 products linked to open cases where the #{team.name} team is the case owner."
      end

      it "highlights the team products tab" do
        expect(highlighted_tab).to eq "Team products"
      end
    end
  end

  context "when there are products" do
    let(:other_user_same_team) { create :user, :activated, has_viewed_introduction: true, team: team }
    let!(:user_product) { create(:product) }
    let!(:other_product) { create(:product) }
    let!(:team_product) { create(:product) }
    let!(:closed_product) { create(:product) }
    let!(:user_case) { create(:allegation, creator: user, products: [user_product]) }
    let!(:other_case) { create(:allegation, products: [other_product]) }
    let!(:team_case) { create(:allegation, creator: other_user_same_team, products: [team_product]) }
    let!(:closed_case) { create(:allegation, creator: user, products: [closed_product], is_closed: true) }

    before do
      Investigation.import refresh: true, force: true
      Product.import refresh: true, force: true
    end

    context "when the user is on the your products page" do
      before do
        click_on "Your products"
      end

      it "shows products that are associated with cases that are owned by the user and open" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_product.psd_ref)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_product.psd_ref)
        expect(page).not_to have_selector("td.govuk-table__cell", text: team_product.psd_ref)
      end

      it "does not show closed cases" do
        expect(page).not_to have_selector("td.govuk-table__cell", text: closed_product.psd_ref)
      end

      context "when less than 12 products" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end
    end

    context "when more than 11 products" do
      before do
        11.times do
          create(:allegation, creator: user, products: [ create(:product) ])
          Investigation.import refresh: true, force: true
          Product.import refresh: true, force: true
        end
        visit "/products/your-products"
      end

      it "does show the sort filter drop down with 'newest cases' sorting option selected" do
        expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")
      end
    end

    context "when the user is on the team cases page" do
      it "shows cases that are owned by the users team" do
        click_on "All products"
        click_on "Team products"
        expect(page).to have_selector("td.govuk-table__cell", text: user_product.psd_ref)
        expect(page).to have_selector("td.govuk-table__cell", text: team_product.psd_ref)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_product.psd_ref)
      end

      it "does not show closed cases" do
        expect(page).not_to have_selector("td.govuk-table__cell", text: closed_product.psd_ref)
      end

      context "when less than 12 cases" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 cases" do
        before do
          10.times do
            create(:allegation, creator: other_user_same_team, products: [ create(:product) ])
            Investigation.import refresh: true, force: true
            Product.import refresh: true, force: true
          end
          visit "/products/team-products"
        end

        it "does show the sort filter drop down with 'newest cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")
        end
      end
    end

    context "when the user is on the all products page" do
      before do
        click_on "All products"
      end

      it "shows all cases" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_product.psd_ref)
        expect(page).to have_selector("td.govuk-table__cell", text: other_product.psd_ref)
        expect(page).to have_selector("td.govuk-table__cell", text: team_product.psd_ref)
      end

      it "highlights the all products tab" do
        expect(highlighted_tab).to eq "All products - Search"
      end

      it "shows closed cases" do
        expect(page).to have_selector("td.govuk-table__cell", text: closed_product.psd_ref)
      end

      context "when less than 12 products" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 products" do
        before do
          9.times do
            create(:allegation, products: [ create(:product) ])
            Investigation.import refresh: true, force: true
            Product.import refresh: true, force: true
          end
          visit "/products/all-products"
        end

        it "does show the sort filter drop down with 'recent products' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")
        end
      end
    end
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
