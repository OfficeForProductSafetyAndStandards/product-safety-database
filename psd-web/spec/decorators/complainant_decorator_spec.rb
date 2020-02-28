require "rails_helper"

RSpec.describe ComplainantDecorator do
  subject(:decorated_complainant) { complainant.decorate }

  let(:complainant) { build(:complainant, investigation: nil) }


  describe "#contact_details" do
    context "with contact details" do
      it "displays the contact details" do
        expect(decorated_complainant.contact_details).to match(Regexp.escape(complainant.name))
        expect(decorated_complainant.contact_details).to match(Regexp.escape(complainant.phone_number))
        expect(decorated_complainant.contact_details).to match(Regexp.escape(complainant.email_address))
        expect(decorated_complainant.contact_details).to match(Regexp.escape(complainant.other_details))
      end
    end

    context "without contact details" do
      let(:complainant) { Complainant.new }

      it { expect(decorated_complainant.contact_details).to eq("Not provided") }
    end
  end

  describe "#other_details" do
    include_examples "a formated text", :complainant, :other_details
  end
end
