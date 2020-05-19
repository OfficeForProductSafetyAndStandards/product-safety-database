require "rails_helper"

RSpec.describe ComplainantDecorator, :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_pundit do
  subject(:decorated_complainant) { complainant.decorate }

  let(:current_user) { create(:user) }
  let(:investigation) { create(:investigation, owner: current_user.team) }
  let(:complainant) { create(:complainant, investigation: investigation) }

  describe "#contact_details" do
    context "with contact details" do
      it "displays the complainant name" do
        expect(decorated_complainant.contact_details(current_user)).to match(Regexp.escape(complainant.name))
      end

      it "displays the complainant phone number" do
        expect(decorated_complainant.contact_details(current_user)).to match(Regexp.escape(complainant.phone_number))
      end

      it "displays the complainant email address" do
        expect(decorated_complainant.contact_details(current_user)).to match(Regexp.escape(complainant.email_address))
      end

      it "displays the complainant other details" do
        expect(decorated_complainant.contact_details(current_user)).to match(Regexp.escape(complainant.other_details))
      end
    end
  end

  describe "#other_details" do
    include_examples "a formated text", :complainant, :other_details
  end
end
