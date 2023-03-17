require "rails_helper"

RSpec.feature "Home page", :with_opensearch, type: :feature do
  context "when user is signed out" do
    scenario "shows the home page" do
      visit unauthenticated_root_path

      expect(page).not_to have_css(".govuk-header .govuk-phase-banner__content__tag")
      expect(page).to have_css(".govuk-phase-banner")

      expect(page).to have_text("Report, track and share product safety information with the product safety community.")
      expect(page).to have_link("Sign in to your account")

      expect(page).not_to have_link("Sign out")
      expect(page).not_to have_link("Your account")
    end
  end

  context "when user is signed in" do
    let(:has_accepted_declaration) { true }
    let(:has_viewed_introduction) { true }
    let(:user_state) { :activated }
    let(:user) { create(:user, user_state, has_accepted_declaration:, has_viewed_introduction:) }

    before do
      sign_in user
    end

    def expect_small_beta_phase_banner
      expect(page).to have_css(".govuk-header .govuk-phase-banner__content__tag")
      expect(page).not_to have_css(".govuk-phase-banner")
    end

    def expect_header_to_have_signed_in_links
      expect(page).to have_link("Sign out")
      # TODO: Remove comment when account page is re-implemented in app
      # expect(page).to have_link("Your account")
      expect(page).not_to have_link("Sign in")
    end

    context "with OPSS user role" do
      let(:user) { create(:user, :opss_user, user_state, has_accepted_declaration:, has_viewed_introduction:) }

      context "when the user has not previously accepted the declaration" do
        let(:has_accepted_declaration) { false }
        let(:has_viewed_introduction) { false }
        let(:user_state) { :inactive }

        scenario "shows the declaration page before the case list" do
          expect(page).to have_current_path(declaration_index_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Declaration")

          check "I agree"
          click_button "Continue"

          expect(page).to have_current_path(authenticated_opss_root_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Home – The Product Safety Database (PSD)")
          expect(page).to have_link("Your cases")
        end
      end

      context "when the user has previously accepted the declaration" do
        scenario "shows the inner home page" do
          expect(page).to have_current_path(authenticated_opss_root_path)
          expect_small_beta_phase_banner
          expect_header_to_have_signed_in_links
          expect(page).to have_text("Home – The Product Safety Database (PSD)")
          expect(page).to have_link("Your cases")
        end
      end
    end

    context "without OPSS user role" do
      context "when the user has not previously accepted the declaration or viewed the introduction" do
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
          expect(page).to have_text("The Product Safety Database (PSD) has been developed with")
          expect(page).to have_link("Continue")
        end
      end

      context "when the user has previously accepted the declaration" do
        context "when the user has not previously viewed the introduction" do
          let(:has_viewed_introduction) { false }

          scenario "shows the introduction" do
            expect(page).to have_current_path(introduction_overview_path)
            expect_small_beta_phase_banner
            expect_header_to_have_signed_in_links
            expect(page).to have_text("The Product Safety Database (PSD) has been developed with")
            expect(page).to have_link("Continue")
          end
        end

        context "when the user has previously viewed the introduction" do
          scenario "shows the non-OPSS home page" do
            expect(page).to have_current_path(authenticated_msa_root_path)
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
