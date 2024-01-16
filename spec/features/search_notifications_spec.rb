RSpec.feature "Searching notifications", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, :can_access_new_search, :opss_user, has_viewed_introduction: true }

  let(:product) do
    create(:product,
           name: "MyBrand washing machine",
           category: "kitchen appliances",
           product_code: "W2020-10/1")
  end
  let!(:investigation) { create(:allegation, products: [product], user_title: nil, reported_reason: "unsafe") }

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

  let!(:mobile_phone_investigation) { create(:allegation, products: [mobile_phone], user_title: "mobile phone investigation", reported_reason: "unsafe") }
  let!(:mobilz_phont_investigation) { create(:notification, products: [mobilz_phont], user_title: "mobilz phone investigation", reported_reason: "unsafe_and_non_compliant") }
  let!(:thirteenproduct_investigation) { create(:enquiry, products: [thirteenproduct], user_title: "thirteenproduct investigation", reported_reason: "non_compliant") }
  let!(:eeirteenproduct_investigation) { create(:project, products: [eeirteenproduct], user_title: "eeirteenproduct investigation", reported_reason: "safe_and_compliant") }

  before do
    Investigation.reindex
  end

  scenario "searching for a notification using a keyword from a product name" do
    sign_in(user)
    visit "/notifications"

    fill_in "Search", with: "MyBrand"
    click_button "Submit search"

    expect_to_be_on_notifications_search_results_page

    expect(page).to have_content "1 notification matching keyword(s) MyBrand, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)

    # Full product name should be shown
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a notification using a close-matching product name keyword" do
    sign_in(user)
    visit "/notifications"

    fill_in "Search", with: "MyBran"
    click_button "Submit search"

    expect_to_be_on_notifications_search_results_page

    expect(page).to have_content "1 notification matching keyword(s) MyBran, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a notification using an exact matching product code" do
    sign_in(user)
    visit "/notifications"

    fill_in "Search", with: "W2020-10/1"
    click_button "Submit search"

    expect_to_be_on_notifications_search_results_page

    expect(page).to have_content "1 notification matching keyword(s) W2020-10/1, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a notification using a query string that includes trailing or leading whitespaces" do
    sign_in(user)
    visit "/notifications"

    fill_in "Search", with: " W2020-10/1   "
    click_button "Submit search"

    expect_to_be_on_notifications_search_results_page

    expect(page).to have_content "1 notification matching keyword(s) W2020-10/1, using the current filters, was found."

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  describe "filtering by notification type" do
    before do
      sign_in(user)
      visit "/notifications"
    end

    it "shows the correct notifications for that type" do
      find("details#case-type").click
      check "Notification"
      check "Allegation"
      check "Project"
      check "Enquiry"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "5 notifications using the current filters, were found."
      expect(page).to have_text(investigation.pretty_id)
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#case-type").click
      uncheck "Allegation"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "3 notifications using the current filters, were found."
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#case-type").click
      uncheck "Enquiry"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "2 notifications using the current filters, were found."
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#case-type").click
      uncheck "Project"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "1 notification using the current filters, was found."
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)

      find("details#case-type").click
      uncheck "Notification"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "5 notifications using the current filters, were found."
      expect(page).to have_text(investigation.pretty_id)
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)
    end
  end

  describe "when filtering based on the created_at date" do
    let!(:old_case) { create(:allegation, products: [product], user_title: title) }
    let!(:new_case) { create(:allegation, products: [mobile_phone], user_title: title) }

    let(:time) { Time.zone.parse("16 Oct 2023 00:00") }
    let(:three_months_ago) { time.advance(months: -3) }
    let(:one_day_ago) { time.advance(days: -1) }

    let(:title) { "interesting notification" }

    before do
      Timecop.freeze(time)
      old_case.update_column(:created_at, three_months_ago)
      new_case.update_column(:created_at, one_day_ago)

      Investigation.reindex
      sign_in(user)
      visit "/notifications"
    end

    after { Timecop.return }

    context "with no date filters applied" do
      before do
        fill_in "Search", with: title
        click_button "Submit search"
      end

      it "shows both notifications" do
        expect_to_be_on_notifications_search_results_page
        expect(page).to have_content "2 notifications matching keyword(s)"

        expect(page).to have_text(old_case.pretty_id)
        expect(page).to have_text(new_case.pretty_id)
      end
    end

    context "with a from date filter applied" do
      before do
        fill_in "Search", with: title

        within_fieldset "Created from" do
          fill_in "change_date_filter-fieldset-created_from_date[day]", with: "14"
          fill_in "change_date_filter-fieldset-created_from_date[month]", with: "10"
          fill_in "change_date_filter-fieldset-created_from_date[year]", with: "2023"
        end

        click_button "Apply"
        click_button "Submit search"
      end

      it "only shows the notification that was last changed within the date range" do
        expect_to_be_on_notifications_search_results_page
        expect(page).to have_content "1 notification matching keyword(s)"

        expect(page).not_to have_text(old_case.pretty_id)
        expect(page).to have_text(new_case.pretty_id)
      end
    end

    context "with a to date filter applied" do
      before do
        fill_in "Search", with: title

        within_fieldset "Created up to" do
          fill_in "change_date_filter-fieldset-created_to_date[day]", with: "14"
          fill_in "change_date_filter-fieldset-created_to_date[month]", with: "10"
          fill_in "change_date_filter-fieldset-created_to_date[year]", with: "2023"
        end

        click_button "Apply"
        click_button "Submit search"
      end

      it "only shows the case that was last changed within the date range" do
        expect_to_be_on_notifications_search_results_page
        expect(page).to have_content "1 notification matching keyword(s)"

        expect(page).to have_text(old_case.pretty_id)
        expect(page).not_to have_text(new_case.pretty_id)
      end
    end
  end

  describe "when filtering by reported reason" do
    before do
      sign_in(user)
      visit "/notifications"
    end

    it "shows the correct notifications for that reason" do
      find("details#reported-reason").click
      check "Unsafe and non-compliant"
      check "Non-compliant"
      check "Unsafe"
      check "Safe and compliant"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "5 notifications using the current filters, were found."
      expect(page).to have_text(investigation.pretty_id)
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#reported-reason").click
      uncheck "Unsafe and non-compliant"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "4 notifications using the current filters, were found."
      expect(page).to have_text(investigation.pretty_id)
      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#reported-reason").click
      uncheck "Unsafe"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "2 notifications using the current filters, were found."
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#reported-reason").click
      uncheck "Non-compliant"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "1 notification using the current filters, was found."
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)

      find("details#reported-reason").click
      uncheck "Safe and compliant"
      click_button "Apply"

      expect_to_be_on_notifications_index_page
      expect(page).to have_content "5 notifications using the current filters, were found."
      expect(page).to have_text(investigation.pretty_id)
      expect(page).to have_text(mobilz_phont_investigation.pretty_id)
      expect(page).to have_text(mobile_phone_investigation.pretty_id)
      expect(page).to have_text(thirteenproduct_investigation.pretty_id)
      expect(page).to have_text(eeirteenproduct_investigation.pretty_id)
    end
  end
end
