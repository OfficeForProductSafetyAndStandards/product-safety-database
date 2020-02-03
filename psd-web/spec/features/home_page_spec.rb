require "rails_helper"

RSpec.feature "Home page", :with_elasticsearch, :with_stubbed_keycloak_config do
  context "User signed out" do
    scenario "shows the home page" do
      sign_out(:user)
      visit root_path

      expect(page).not_to have_css(".psd-header .govuk-phase-banner__content__tag")
      expect(page).to have_css(".govuk-phase-banner")

      expect(page).to have_text("Report, track and share product safety information with the product safety community.")
      expect(page).to have_link("Sign in to your account")

      expect(page).not_to have_link("Sign out")
      expect(page).not_to have_link("Your account")
    end
  end

  context "Signed in" do
    let(:has_accepted_declaration) { true }
    let(:has_viewed_introduction) { true }
    let(:user_state) { :activated }

    before do
      sign_in(as_user: create(:user, user_state, role, has_accepted_declaration: has_accepted_declaration, has_viewed_introduction: has_viewed_introduction))
      visit root_path
    end

    def expect_small_beta_phase_banner
      expect(page).to have_css(".psd-header .govuk-phase-banner__content__tag")
      expect(page).not_to have_css(".govuk-phase-banner")
    end

    def expect_header_to_have_signed_in_links
      expect(page).to have_link("Sign out")
      expect(page).to have_link("Your account")
      expect(page).not_to have_link("Sign in")
    end

    context "as OPSS user" do
      let(:role) { :opss_user }

      context "not previously accepted the declaration" do
        let(:has_accepted_declaration) { false }
        let(:user_state) { :inactive }

        scenario "shows the declaration page before the case list" do
          expect(page).to have_current_path(declaration_index_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Declaration")

          check "I agree"
          click_button "Continue"

          expect(page).to have_current_path(investigations_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Cases")
          expect(page).to have_link("Open a new case")
        end
      end

      context "previously accepted the declaration" do
        scenario "shows the case list" do
          expect(page).to have_current_path(investigations_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Cases")
          expect(page).to have_link("Open a new case")
        end
      end
    end

    context "as non-OPSS user" do
      let(:role) { :psd_user }

      context "not previously accepted the declaration or viewed the introduction" do
        let(:has_accepted_declaration) { false }
        let(:has_viewed_introduction) { false }
        let(:user_state) { :inactive }

        scenario "shows the declaration page before the introduction" do
          expect(page).to have_current_path(declaration_index_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Declaration")

          check "I agree"
          click_button "Continue"

          expect(page).to have_current_path(introduction_overview_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("The Product safety database (PSD) has been developed with")
          expect(page).to have_link("Continue")
        end
      end

      context "previously accepted the declaration" do
        context "not previously viewed the introduction" do
          let(:has_viewed_introduction) { false }

          scenario "shows the introduction" do
            expect(page).to have_current_path(introduction_overview_path)
            expect_small_beta_phase_banner
            expect_header_to_have_signed_in_links
            expect(page).to have_text("The Product safety database (PSD) has been developed with")
            expect(page).to have_link("Continue")
          end
        end

        context "previously viewed the introduction" do
          scenario "shows the non-OPSS home page" do
            expect(page).to have_current_path(root_path)
            expect_small_beta_phase_banner
            expect_header_to_have_signed_in_links
            expect(page).to have_link("Your cases")
            expect(page).to have_link("All cases")
            expect(page).to have_link("More information")
          end
        end
      end
    end
  end
end
