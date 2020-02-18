require "application_system_test_case"

class InvestigationSubNavigation < ApplicationSystemTestCase
  setup do
    Investigation.import force: true, refresh: :wait_for
    stub_notify_mailer
    stub_antivirus_api
    sign_in

    @investigation = load_case(:one)
  end

  test "able to navigate to all the relevant pages" do
    visit investigation_path(@investigation)

    products_link    = "Products (#{@investigation.products.count})"
    businesses_link  = "Businesses (#{@investigation.businesses.count})"
    attachments_link = "Attachments (#{@investigation.documents.count})"
    activity_link    = "Activity"

    with_options class: "hmcts-sub-navigation__link" do |p|
      p.assert_link "Overview",
                    href: investigation_path(@investigation)
      p.assert_link products_link,
                    href: investigation_products_path(@investigation)
      p.assert_link businesses_link,
                    href: investigation_businesses_path(@investigation)
      p.assert_link attachments_link,
                    href: investigation_attachments_path(@investigation)
      p.assert_link activity_link,
                    href: investigation_activity_path(@investigation)
    end

    click_link products_link
    assert_css "h1.govuk-heading-l", text: "Products"

    click_link businesses_link
    assert_css "h1.govuk-heading-l", text: "Businesses"

    click_link attachments_link
    assert_css "h1.govuk-heading-l", text: "Attachments"

    click_link activity_link
    assert_css "h1.govuk-heading-l", text: "Activity"
  end
end
