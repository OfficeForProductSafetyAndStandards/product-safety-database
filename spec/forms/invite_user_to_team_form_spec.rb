require "rails_helper"

RSpec.describe InviteUserToTeamForm do
  subject(:form) { described_class.new(email:, team:) }

  let(:email) { "test@example.com" }
  let(:team) { create(:team, name: "Test Team") }

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

    context "when no email is supplied" do
      let(:email) { nil }

      include_examples "invalid form", [:email, "Enter an email address in the correct format, like name@example.com"]
    end

    context "when no team is supplied" do
      let(:team) { nil }

      include_examples "invalid form", [:team, "Team cannot be blank"]
    end

    context "when an invalid email is supplied" do
      let(:email) { "test" }

      include_examples "invalid form", [:email, "Enter an email address in the correct format, like name@example.com"]
    end

    context "when non-whitelisted email is supplied" do
      context "with whitelisting disabled" do
        before { set_whitelisting_enabled(false) }

        include_examples "valid form"
      end

      context "with whitelisting enabled" do
        before { set_whitelisting_enabled(true) }

        include_examples "invalid form", [:email, "The email address is not recognised. Check you’ve entered it correctly, or email opss.enquiries@beis.gov.uk to add it to the approved list."]
      end
    end

    context "with whitelisting enabled" do
      let(:email) { "test@beis.gov.uk" }

      before { set_whitelisting_enabled(true) }

      include_examples "valid form"

      context "when whitelisted email is supplied and uppercased" do
        let(:email) { "test@BEIS.gov.uk" }

        include_examples "valid form"
      end

      context "when incorrectly formatted email is supplied" do
        let(:email) { "an.onymous:sheffield.gov.uk" }

        include_examples "invalid form", [:email, "Enter an email address in the correct format, like name@example.com"]
      end
    end

    context "with an existing user" do
      let(:user_trait) { nil }
      let(:user_team) { create(:team) }
      let(:user_email) { email }

      before { create(:user, user_trait, email: user_email, team: user_team) }

      context "when the user is deleted" do
        let(:user_trait) { :deleted }

        include_examples "valid form", [:email, "Email address belongs to a user that has been deleted. Email OPSS if you would like their account restored."]
      end

      context "when the user is on a different team" do
        include_examples "invalid form", [:email, "You cannot invite this person to join your team because they are already a member of another team. Contact opss.enquiries@beis.gov.uk if the person’s team needs to be changed."]
      end

      context "when the user is on the same team" do
        let(:user_team) { team }

        context "when the user is activated" do
          let(:user_trait) { :activated }

          include_examples "invalid form", [:email, "test@example.com is already a member of Test Team"]

          context "when the supplied email is in a different case to the existing user email" do
            let(:email) { "TEst@example.com" }

            include_examples "invalid form", [:email, "TEst@example.com is already a member of Test Team"]
          end
        end

        context "when the user is not activated" do
          let(:user_trait) { :inactive }

          include_examples "valid form"
        end
      end
    end
  end
end
