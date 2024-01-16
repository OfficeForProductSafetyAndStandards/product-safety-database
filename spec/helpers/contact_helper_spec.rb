RSpec.describe ContactHelper do
  describe "#name_and_email" do
    context "when both name and contact details are present" do
      it "returns both, with the contact details in brackets" do
        expect(name_and_contact_details("Bob ", "bob@example.com ")).to eql("Bob (bob@example.com)")
      end
    end

    context "when only name is present" do
      it "returns the name" do
        expect(name_and_contact_details("Bob", " ")).to eql("Bob")
      end
    end

    context "when only contact details are present" do
      it "returns the contact details" do
        expect(name_and_contact_details(" ", "07700 900 982 ")).to eql("07700 900 982")
      end
    end

    context "when both are blank" do
      it "returns nil" do
        expect(name_and_contact_details(" ", " ")).to be nil
      end
    end
  end
end
