require "rails_helper"

RSpec.describe ComplainantDecorator, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:decorated_complainant) { complainant.decorate }
  let(:viewing_user) { create(:user) }
  let(:investigation) { create(:investigation, owner: viewing_user.team) }
  let(:complainant) { create(:complainant, investigation: investigation) }

  describe "#contact_details" do
    before do
      # Sadly I have to use allow_any_instance_of as pundit embed itself deep into ActionController
      allow_any_instance_of(ApplicationController) # rubocop:disable Rspec/AnyInstance
        .to receive(:pundit_user).and_return(viewing_user)
    end

    context "with contact details" do
      it "displays the complainant name" do
        expect(decorated_complainant.contact_details(viewing_user)).to match(Regexp.escape(complainant.name))
      end

      it "displays the complainant phone number" do
        expect(decorated_complainant.contact_details(viewing_user)).to match(Regexp.escape(complainant.phone_number))
      end

      it "displays the complainant email address" do
        expect(decorated_complainant.contact_details(viewing_user)).to match(Regexp.escape(complainant.email_address))
      end

      it "displays the complainant other details" do
        expect(decorated_complainant.contact_details(viewing_user)).to match(Regexp.escape(complainant.other_details))
      end
    end
  end

  describe "#other_details" do
    include_examples "a formated text", :complainant, :other_details
  end
end
