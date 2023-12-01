require "rails_helper"

RSpec.describe ChangeCaseOwnerForm do
  subject(:form) { described_class.new(owner_id:, owner_rationale: rationale) }

  let(:owner) { create(:team) }

  let(:owner_id) { owner.id }
  let(:rationale) { "Test rationale" }

  describe "#valid?" do
    shared_examples_for "valid form" do
      it "is is valid" do
        expect(form).to be_valid
      end

      it "does not contain error messages" do
        form.validate
        expect(form.errors.full_messages).to be_empty
      end
    end

    shared_examples_for "invalid form" do |*errors|
      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        form.validate
        errors.each do |property, message|
          expect(form.errors.full_messages_for(property)).to eq([message])
        end
      end
    end

    context "when no owner_id is supplied" do
      let(:owner_id) { nil }

      include_examples "invalid form", [:owner_id, "Select notification owner"]
    end

    context "when owner_id does not match a user or team" do
      let(:owner_id) { "invalid" }

      include_examples "invalid form", [:owner_id, "User or team not found"]
    end

    context "when owner is an inactive user" do
      let(:owner) { create(:user, :inactive) }

      include_examples "invalid form", [:owner_id, "User or team not found"]
    end
  end

  describe "#owner" do
    it "returns the owner" do
      expect(form.owner).to eq(owner)
    end
  end
end
