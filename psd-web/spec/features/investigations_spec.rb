require "rails_helper"

RSpec.feature "Investigation listing", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config, type: :feature do
  describe "default relevance" do
    let(:user) { create :user, :activated, has_viewed_introduction: true }
    let(:pagination_link_params) do
      {
        allegation: :unchecked,
        assigned_to_me: :unchecked,
        assigned_to_someone_else: :unchecked,
        created_by_me: :unchecked,
        created_by_someone_else: :unchecked,
        enquiry: :unchecked,
        page: 2,
        project: :unchecked,
        status_open: :checked
      }
    end

    let!(:investigation_last_updated_3_days_ago) { create(:allegation, updated_at: 3.days.ago, description: "Electric skateboard investigation").decorate }
    let!(:investigation_last_updated_2_days_ago) { create(:allegation, updated_at: 2.days.ago, description: "FastToast toaster investigation").decorate }
    let!(:investigation_last_updated_1_days_ago) { create(:allegation, updated_at: 1.day.ago,  description: "Counterfeit chargers investigation").decorate }

    before do
      allow(AuditActivity::Investigation::Base).to receive(:from)
      create_list :project, 18, updated_at: 4.days.ago
    end

    scenario "lists cases correctly sorted" do
      # it is necessary to re-import and wait for the indexing to be done.
      Investigation.import refresh: :wait_for

      sign_in(as_user: user)
      visit investigations_path

      # Expect investigations to be in reverse chronological order
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(1) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_1_days_ago.pretty_description)
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(2) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_2_days_ago.pretty_description)
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(3) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_3_days_ago.pretty_description)

      expect(page).to have_css(".pagination em.current", text: 1)
      expect(page).to have_link("2",      href: /#{Regexp.escape(investigations_path(pagination_link_params))}/)
      expect(page).to have_link("Next →", href: /#{Regexp.escape(investigations_path(pagination_link_params))}/)

      fill_in "Keywords", with: "electric skateboard"
      click_on "Apply filters"

      # Expect only the single relevant investigation to be returned
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(1) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_3_days_ago.pretty_description)


      expect(page.find("input[name='sort_by'][value='#{SearchParams::RELEVANT}']")).to be_checked

      expect(page).to have_current_path(investigations_search_path, ignore_query: true)

      fill_in "Keywords", with: ""
      click_on "Apply filters"

      expect(page).not_to have_css("input[name='sort_by'][value='#{SearchParams::RELEVANT}']")

      # Expect investigations to be back in reverse chronological order again
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(1) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_1_days_ago.pretty_description)
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(2) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_2_days_ago.pretty_description)
      expect(page).
        to have_css(".govuk-grid-row.psd-case-card:nth-child(3) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_3_days_ago.pretty_description)

      expect(page).to have_current_path(investigations_path, ignore_query: true)

      choose "Least recently updated"
      click_on "Apply filters"

      expect(page.find("input[name='sort_by'][value='#{SearchParams::OLDEST}']")).to be_checked
    end
  end

  describe "when signed in as a trading standard officer" do
    let(:my_organisation)       { create(:organisation) }
    let(:me)                    { create(:user, :activated, has_viewed_introduction: true) }
    let(:teammate)              { create(:user, :activated) }
    let(:opss_user)             { create(:user, :activated, :opss_user) }
    let!(:assigned_to_me)        { create(:allegation, assignable: me.reload).decorate }
    let!(:assigned_to_teamate)   { create(:allegation, assignable: teammate.reload).decorate }
    let!(:assigned_to_opss_user) { create(:allegation, assignable: opss_user.reload).decorate }

    before do
      allow(AuditActivity::Investigation::Base).to receive(:from)
      ap me
      create(:team, organisation: my_organisation, users: [me, teammate])
    end

    scenario "your cases link show only cases assigned to me" do
      Investigation.import refresh: :wait_for

      sign_in(as_user: me)

      click_link "Your cases"

      save_and_open_page

      expect(page).to     show_case_card_with(text: assigned_to_me.pretty_description)
      expect(page).not_to show_case_card_with(text: assigned_to_teamate.pretty_description)
      expect(page).not_to show_case_card_with(text: assigned_to_opss_user.pretty_description)


      # expect(page).
      # to have_css(".govuk-grid-row.psd-case-card:nth-child(1) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_1_days_ago.pretty_description)

    end
  end
end
