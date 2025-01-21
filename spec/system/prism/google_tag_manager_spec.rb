require "rails_helper"

RSpec.describe "Google Tag Manager in PRISM", type: :system do
  include Prism::Engine.routes.url_helpers

  let(:user) { create(:user) }
  let(:risk_assessment) { create(:prism_risk_assessment, created_by_user_id: user.id) }
  let(:gtm_containers) { %w[GTM-K2S954RK] }

  def set_cookie_preferences(accept_analytics: true)
    page.driver.browser.set_cookie("accept_analytics_cookies=#{accept_analytics}")
    page.driver.browser.set_cookie("cookie_preferences_set=true")
  end

  shared_examples "has no GTM containers" do
    it "does not include GTM script tags" do
      gtm_containers.each do |container|
        expect(page).not_to have_selector("script", visible: false, text: /#{container}/)
      end
    end

    it "does not include GTM noscript iframes" do
      gtm_containers.each do |container|
        expect(page).not_to have_selector("noscript iframe[src*='#{container}']", visible: false)
      end
    end
  end

  before do
    sign_in(user)
    driven_by(:rack_test)
  end

  context "when in production" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    context "when analytics cookies are accepted" do
      before do
        set_cookie_preferences(accept_analytics: true)
        visit risk_assessment_tasks_path(risk_assessment)
      end

      it "includes GTM script tags" do
        gtm_containers.each do |container|
          expect(page).to have_selector("script", visible: false, text: /#{container}/)
        end
      end

      it "includes GTM noscript iframes" do
        gtm_containers.each do |container|
          expect(page).to have_selector("noscript iframe[src*='#{container}']", visible: false)
        end
      end
    end

    context "when analytics cookies are not accepted" do
      before do
        set_cookie_preferences(accept_analytics: false)
        visit risk_assessment_tasks_path(risk_assessment)
      end

      include_examples "has no GTM containers"
    end
  end

  context "when not in production" do
    before do
      visit risk_assessment_tasks_path(risk_assessment)
    end

    include_examples "has no GTM containers"
  end
end
