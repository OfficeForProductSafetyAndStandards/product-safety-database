require "application_system_test_case"

class InvestigationSubNavigation < ApplicationSystemTestCase
  driven_by :selenium

  setup do
    mock_out_keycloak_and_notify
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
                    href: investigation_url(@investigation)
      p.assert_link products_link,
                    href: investigation_products_url(@investigation)
      p.assert_link businesses_link,
                    href: investigation_businesses_url(@investigation)
      p.assert_link attachments_link,
                    href: investigation_attachments_url(@investigation)
      p.assert_link activity_link,
                    href: investigation_activity_url(@investigation)
    end

    click_link products_link
    assert_css "h2.govuk-heading-m", text: "Products"

    click_link businesses_link
    assert_css "h2.govuk-heading-m", text: "Businesses"

    click_link attachments_link
    assert_css "h2.govuk-heading-m", text: "Attachments"

    click_link activity_link
    assert_css "h2.govuk-heading-m", text: "Activity"
  end
end
