require "rails_helper"

RSpec.describe ContactHelper do
  describe "#name_and_email" do
    context "when both name and email are present" do
      it "returns both, with the email in brackets" do
        expect(name_and_email("Bob ", "bob@example.com ")).to eql("Bob (bob@example.com)")
      end
    end

    context "when only name is present" do
      it "returns the name" do
        expect(name_and_email("Bob", " ")).to eql("Bob")
      end
    end

    context "when only email is present" do
      it "returns the name" do
        expect(name_and_email(" ", "bob@example.com ")).to eql("bob@example.com")
      end
    end

    context "when both are blank" do
      it "returns nil" do
        expect(name_and_email(" ", " ")).to be nil
      end
    end
  end
end
