require "rails_helper"

RSpec.describe "layouts/prism/application", type: :view do
  include Devise::Test::ControllerHelpers

  let(:warden) do
    warden = instance_double(Warden::Proxy)
    allow(warden).to receive_messages(authenticate: nil, authenticate?: false, user: nil)
    warden
  end

  before do
    view.extend(CookiesConcern)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    allow(view).to receive(:t).with(:enquiries_email).and_return("test@example.com")
    allow(view).to receive_messages(
      current_user: nil,
      image_path: "",
      main_app: instance_double(
        Rails.application.routes.url_helpers,
        destroy_user_session_path: "/users/sign_out",
        help_about_path: "/help/about",
        help_accessibility_path: "/help/accessibility",
        help_privacy_notice_path: "/help/privacy",
        help_terms_and_conditions_path: "/help/terms",
        help_cookies_policy_path: "/help/cookies"
      ),
      stylesheet_link_tag: "",
      javascript_include_tag: "",
      csrf_meta_tags: ""
    )
    allow(view).to receive(:render).and_call_original
    without_partial_double_verification do
      allow(view).to receive(:user_signed_in?).and_return(false)
    end

    # Set up request environment for Devise
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["warden"] = warden

    # Assign content for yield blocks
    view.content_for(:page_title, "Test Page")
    view.content_for(:extra_javascript, "")
  end

  context "when analytics cookies are accepted" do
    before do
      allow(view).to receive(:analytics_cookies_accepted?).and_return(true)
      allow(view).to receive(:render).with("shared/ga_head").and_return("GTM head content")
      allow(view).to receive(:render).with("shared/ga_body").and_return("GTM body content")
    end

    it "includes GTM containers in head" do
      render
      expect(rendered).to include("GTM head content")
    end

    it "includes GTM noscript iframes in body" do
      render
      expect(rendered).to include("GTM body content")
    end
  end

  context "when analytics cookies are not accepted" do
    before do
      allow(view).to receive(:analytics_cookies_accepted?).and_return(false)
    end

    it "does not include GTM containers" do
      render
      expect(rendered).not_to include("GTM head content")
      expect(rendered).not_to include("GTM body content")
    end
  end

  context "when not in production" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
    end

    it "does not include GTM containers" do
      render
      expect(rendered).not_to include("GTM head content")
      expect(rendered).not_to include("GTM body content")
    end
  end
end
