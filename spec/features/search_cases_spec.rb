require "rails_helper"

RSpec.feature "Searching cases", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }

  let(:product) do
    create(:product,
           name: "MyBrand washing machine",
           category: "kitchen appliances",
           product_code: "W2020-10/1")
  end
  let!(:investigation) { create(:allegation, products: [product], user_title: nil) }
  let!(:deleted_investigation) { create(:allegation, products: [product], user_title: "DeletedCase", deleted_at: Time.zone.now) }

  let(:mobile_phone) do
    create(:product,
           name: "T12 mobile phone",
           category: "consumer electronics",
           subcategory: "telephone",
           barcode: "11111",
           description: "Original",
           product_code: "AAAAA")
  end

  let(:mobilz_phont) do
    create(:product,
           name: "T12 mobilz phont",
           category: "consumer electronics")
  end

  let(:thirteenproduct) do
    create(:product,
           name: "thirteenproduct",
           category: "consumer electronics")
  end

  let(:eeirteenproduct) do
    create(:product,
           name: "eeirteenproduct",
           category: "consumer electronics")
  end

  let!(:mobile_phone_investigation) { create(:allegation, products: [mobile_phone], user_title: "mobile phone investigation") }
  let!(:mobilz_phont_investigation) { create(:allegation, products: [mobilz_phont], user_title: "mobilz phone investigation") }
  let!(:thirteenproduct_investigation) { create(:allegation, products: [thirteenproduct], user_title: "thirteenproduct investigation") }
  let!(:eeirteenproduct_investigation) { create(:allegation, products: [eeirteenproduct], user_title: "eeirteenproduct investigation") }

  before do
    Investigation.reindex
  end

  scenario "searching for a case using a keyword from a product name" do
    sign_in(user)
    visit "/cases"

    fill_in "Search", with: "MyBrand"
    click_button "Submit search"

    expect_to_be_on_cases_search_results_page

    expect(page).to have_content "1 case matching keyword(s) MyBrand, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)

    # Full product name should be shown
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a case using a close-matching product name keyword" do
    sign_in(user)
    visit "/cases"

    fill_in "Search", with: "MyBran"
    click_button "Submit search"

    expect_to_be_on_cases_search_results_page

    expect(page).to have_content "1 case matching keyword(s) MyBran, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a case using an exact matching product code" do
    sign_in(user)
    visit "/cases"

    fill_in "Search", with: "W2020-10/1"
    click_button "Submit search"

    expect_to_be_on_cases_search_results_page

    expect(page).to have_content "1 case matching keyword(s) W2020-10/1, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a case using a query string that includes trailing or leading whitespaces" do
    sign_in(user)
    visit "/cases"

    fill_in "Search", with: " W2020-10/1   "
    click_button "Submit search"

    expect_to_be_on_cases_search_results_page

    expect(page).to have_content "1 case matching keyword(s) W2020-10/1, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for cases using multiple keywords" do
    pending 'this will be fixed once we re-add fuzzy "or" matching on'
    sign_in(user)
    visit "/cases"

    fill_in "Search", with: "mybrand mobile phone"
    click_button "Submit search"

    expect_to_be_on_cases_search_results_page

    expect(page).to have_content "2 cases matching keyword(s) mybrand mobile phone, using the current filters, was found."

    # Both cases returned even though neither matches ALL the keywords
    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")

    expect(page).to have_text(mobile_phone_investigation.pretty_id)
    expect(page).to have_text("T12 mobile phone")
  end

  xcontext "with fuzzy matching" do
    pending "this is failing as fuzziness rules have now changed - await new rules from business"

    it "does not allow any edits for words less than 6 letters long" do
      sign_in(user)
      visit "/cases"

      fill_in "Search", with: "phone"
      click_button "Submit search"

      expect_to_be_on_cases_search_results_page

      expect(page).to have_content "1 case matching keyword(s) phone, using the current filters, was found."

      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text("T12 mobile phone")

      expect(page).not_to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).not_to have_text("T12 mobilz phont")
    end

    it "allows 1 edit for words more than 6 letters but less than 13 long" do
      sign_in(user)
      visit "/cases"

      fill_in "Search", with: "mobile"
      click_button "Submit search"

      expect_to_be_on_cases_search_results_page

      expect(page).to have_content "2 cases matching keyword(s) mobile, using the current filters, were found."

      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text("T12 mobile phone")

      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text("T12 mobilz phont")
    end

    it "does not allow 2 edits for words more than 6 letters but less than 13 long" do
      sign_in(user)
      visit "/cases"

      fill_in "Search", with: "mobiee"
      click_button "Submit search"

      expect_to_be_on_cases_search_results_page

      expect(page).to have_content "1 case matching keyword(s) mobiee, using the current filters, was found."

      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text("T12 mobile phone")

      expect(page).not_to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).not_to have_text("T12 mobilz phont")
    end

    it "allows 2 edits for words more than 12 long" do
      sign_in(user)
      visit "/cases"

      fill_in "Search", with: "thirteenproduct"
      click_button "Submit search"

      expect_to_be_on_cases_search_results_page

      expect(page).to have_content "2 cases matching keyword(s) thirteenproduct, using the current filters, were found."

      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text("thirteenproduct")

      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)
      expect(page).to have_text("eeirteenproduct")
    end

    it "does not allow 3 edits for words more than 12 long" do
      sign_in(user)
      visit "/cases"

      fill_in "Search", with: "thirteenproduce"
      click_button "Submit search"

      expect_to_be_on_cases_search_results_page

      expect(page).to have_content "1 case matching keyword(s) thirteenproduce, using the current filters, was found."

      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text("thirteenproduct")

      expect(page).not_to have_text(eeirteenproduct_investigation.pretty_id)
      expect(page).not_to have_text("eeirteenproduct")
    end

    context "when no search term is used" do
      it " does not show any deleted cases, but does show all none deleted cases if no word is searched for" do
        sign_in(user)
        visit "/cases"

        fill_in "Search", with: ""
        click_button "Submit search"

        expect(page).to have_content "5 cases using the current filters, were found."

        expect(page).to have_text(thirteenproduct_investigation.pretty_id)
        expect(page).to have_text(thirteenproduct_investigation.user_title)

        expect(page).to have_text(eeirteenproduct_investigation.pretty_id)
        expect(page).to have_text(eeirteenproduct_investigation.user_title)

        expect(page).to have_text(mobile_phone_investigation.pretty_id)
        expect(page).to have_text(mobile_phone_investigation.user_title)

        expect(page).to have_text(mobilz_phont_investigation.pretty_id)
        expect(page).to have_text(mobilz_phont_investigation.user_title)

        expect(page).not_to have_text(deleted_investigation.pretty_id)
        expect(page).not_to have_text(deleted_investigation.user_title)

        expect(page).to have_text(investigation.pretty_id)
        expect(page).to have_text("MyBrand washing machine")
      end

      context "when over 10k cases exist" do
        # rubocop:disable RSpec/VerifiedDoubles
        before do
          spy = spy("not_deleted")
          allow(Investigation).to receive(:not_deleted).and_return(spy)
          allow(spy).to receive(:count).and_return(10_001)
          sign_in(user)
        end
        # rubocop:enable RSpec/VerifiedDoubles

        it "shows total number of cases" do
          visit "/cases"
          within_fieldset "Case status" do
            choose "All"
          end
          click_button "Apply"

          expect(page).to have_content "10001 cases using the current filters, were found."
        end
      end
    end

    context "when searching for a case that has been deleted" do
      it "does not show the deleted case in the results" do
      end
    end

    context "when searching by product subcategory" do
      context "when case is closed" do
        before do
          ChangeCaseStatus.call!(new_status: "closed", investigation: mobile_phone_investigation, user:)
          mobile_phone.update!(subcategory: "handset", barcode: "22222", description: "anewone", product_code: "BBBBB")
          Investigation.reindex

          sign_in(user)
          visit "/cases"
          within_fieldset "Case status" do
            choose "All"
          end
        end

        it "only shows the case when searching by product details from the time the case was closed" do
          pending "This is completely mental and should probably not have gone live. This is matching cases to the old & updated attributes of the products?"
          fill_in "Search", with: "telephone"
          click_button "Submit search"

          expect(page).to have_content "1 case matching keyword(s) telephone, using the current filters, was found."

          expect(page).to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "11111"
          click_button "Submit search"

          expect(page).to have_content "1 case matching keyword(s) 11111, using the current filters, was found."

          expect(page).to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "original"
          click_button "Submit search"

          expect(page).to have_content "1 case matching keyword(s) original, using the current filters, was found."

          expect(page).to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "AAAAA"
          click_button "Submit search"

          expect(page).to have_content "1 case matching keyword(s) AAAAA, using the current filters, was found."

          expect(page).to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "handset"
          click_button "Submit search"

          expect(page).to have_content "0 cases matching keyword(s) handset, using the current filters, were found."

          expect(page).not_to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "22222"
          click_button "Submit search"

          expect(page).to have_content "0 cases matching keyword(s) 22222, using the current filters, were found."

          expect(page).not_to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "anewone"
          click_button "Submit search"

          expect(page).to have_content "0 cases matching keyword(s) anewone, using the current filters, were found."

          expect(page).not_to have_text(mobile_phone_investigation.pretty_id)

          fill_in "Search", with: "BBBBB"
          click_button "Submit search"

          expect(page).to have_content "0 cases matching keyword(s) BBBBB, using the current filters, were found."

          expect(page).not_to have_text(mobile_phone_investigation.pretty_id)
        end
      end
    end
  end

  describe "when filtering based on the date of last change" do
    let!(:old_case) { create(:allegation, products: [product], user_title: title) }
    let!(:new_case) { create(:allegation, products: [mobile_phone], user_title: title) }

    let(:time) { Time.zone.parse("16 Oct 2023 00:00") }
    let(:three_months_ago) { time.advance(months: -3) }
    let(:one_day_ago) { time.advance(days: -1) }

    let(:title) { "interesting case" }

    before do
      Timecop.freeze(time)
      old_case.update_column(:updated_at, three_months_ago)
      new_case.update_column(:updated_at, one_day_ago)

      Investigation.reindex
      sign_in(user)
      visit "/cases"
    end

    after { Timecop.return }

    context "with no date filters applied" do
      before do
        fill_in "Search", with: title
        click_button "Submit search"
      end

      it "shows both cases" do
        expect_to_be_on_cases_search_results_page
        expect(page).to have_content "2 cases matching keyword(s) #{title}, using the current filters, were found."

        expect(page).to have_text(old_case.pretty_id)
        expect(page).to have_text(new_case.pretty_id)
      end
    end

    context "with a date filter applied" do
      before do
        fill_in "Search", with: title
        find("details#filter-details").click

        within_fieldset "Updated after" do
          fill_in "change_date_filter-fieldset-last_change[day]", with: "14"
          fill_in "change_date_filter-fieldset-last_change[month]", with: "10"
          fill_in "change_date_filter-fieldset-last_change[year]", with: "2023"
        end

        click_button "Apply"
        click_button "Submit search"
      end

      it "only shows the case that was last changed within the date range" do
        expect_to_be_on_cases_search_results_page
        expect(page).to have_content "1 case matching keyword(s) #{title}, using the current filters, was found."

        expect(page).to have_text(old_case.pretty_id)
        expect(page).not_to have_text(new_case.pretty_id)
      end
    end
  end
end
