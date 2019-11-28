require "rails_helper"

RSpec.describe ComplainantDecorator do
  fixtures :complainants

  let(:complainant) { complainants(:one) }

  subject { complainant.decorate }

  describe "#contact_details" do
    context "with contact details" do
      it "displays the contact details" do
        expect(subject.contact_details).to match(complainant.name)
        expect(subject.contact_details).to match(complainant.phone_number)
        expect(subject.contact_details).to match(complainant.email_address)
        expect(subject.contact_details).to match(complainant.other_details)
      end
    end

    context "without contact details" do
      let(:complainant) { Complainant.new }

      it { expect(subject.contact_details).to eq("Not provided") }
    end
  end
end
