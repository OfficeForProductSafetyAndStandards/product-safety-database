require "rails_helper"

RSpec.describe User do
  include ActiveSupport::Testing::TimeHelpers

  describe "attributes" do
    let(:user) { described_class.new }

    describe "invitation_token" do
      before { allow(SecureRandom).to receive(:hex).with(15).and_return(expected_token) }

      let(:expected_token) { "abcd1234" }

      it "is generated on instantiation" do
        expect(user.invitation_token).to eq(expected_token)
      end
    end

    describe "invited_at" do
      it "is generated on instantiation" do
        expect(user.invited_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end

  describe "validations" do
    before { user.validate(:registration_completion) }

    context "with registration_completion context" do
      context "with blank mobile number" do
        let(:user) { build(:user, mobile_number: "") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:mobile_number]).to eq ["Enter your mobile number"]
        end
      end

      context "with invalid mobile number format" do
        let(:user) { build(:user, mobile_number: "01111111111") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:mobile_number]).to eq [
            "Enter your mobile number in the correct format, like 07700 900 982"
          ]
        end
      end

      context "with blank name" do
        let(:user) { build(:user, name: "") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:name]).to eq ["Enter your full name"]
        end
      end

      context "with blank password" do
        let(:user) { build(:user, password: "") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:password]).to eq ["Enter a password"]
        end
      end

      context "with a password that is too short" do
        let(:user) { build(:user, password: "123456") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:password])
            .to eq ["Password is too short"]
        end
      end

      context "with a commonly-used password" do
        let(:user) { build(:user, password: "password") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:password])
            .to eq ["Choose a less frequently used password"]
        end
      end
    end
  end

  describe ".active" do
    it "returns only users with activated accounts and not marked as deleted" do
      create(:user, :inactive)
      create(:user, :activated, :deleted)

      active_user = create(:user, :activated)

      expect(described_class.active.to_a).to eq [active_user]
    end
  end

  describe "#has_filled_out_account_setup_form_and_verified_number?" do
    it "returns true if user mobile_number_verified and name details are present" do
      user = create(:user)

      expect(user.has_filled_out_account_setup_form_and_verified_number?).to eq true
    end

    it "returns false if name is nil" do
      user = create(:user, name: nil)

      expect(user.has_filled_out_account_setup_form_and_verified_number?).to eq false
    end

    it "returns false if mobile_number_verified is not verified" do
      user = create(:user, mobile_number_verified: false)

      expect(user.has_filled_out_account_setup_form_and_verified_number?).to eq false
    end
  end

  describe ".not_deleted" do
    it "returns only users without deleted timestamp" do
      create(:user, :deleted)
      not_deleted_user = create(:user)

      expect(described_class.not_deleted.to_a).to eq [not_deleted_user]
    end
  end

  describe ".get_owners" do
    let!(:active_user) { create(:user, :activated) }
    let!(:inactive_user) { create(:user, :inactive) }

    it "returns other users" do
      expect(described_class.get_owners).to include(active_user)
    end

    it "does not return other users who are not activated" do
      expect(described_class.get_owners).not_to include(inactive_user)
    end

    it "includes associations needed for display_name" do
      owners = described_class.get_owners.to_a # to_a forces the query execution and load immediately
      expect(lambda {
        owners.map { |owner| owner.decorate.display_name(viewer: active_user) }
      }).to not_talk_to_db
    end

    context "when a user to except is supplied" do
      it "does not return the excepted user" do
        expect(described_class.get_owners(except: active_user)).to be_empty
      end
    end
  end

  describe "#send_reset_password_instructions" do
    subject(:user) { create(:user) }

    let!(:reset_token) { stubbed_devise_generated_token }

    it "enqueues a job posting email to notify with the none encrypted token", :with_test_queue_adapter do
      message_delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      allow(NotifyMailer).to receive(:reset_password_instructions).with(user, reset_token.first).and_return(message_delivery)

      user.send_reset_password_instructions

      expect(message_delivery).to have_received(:deliver_later)
    end
  end

  describe "#invitation_expired?" do
    it "returns false when user was invited less than 14 days ago" do
      user = build_stubbed(:user, invited_at: 13.days.ago)
      expect(user.invitation_expired?).to be false
    end

    it "returns true when user was invited exactly 14 days ago" do
      user = build_stubbed(:user, invited_at: 14.days.ago)
      expect(user.invitation_expired?).to be true
    end

    it "returns true when user was invited more than 14 days ago" do
      user = build_stubbed(:user, invited_at: 15.days.ago)
      expect(user.invitation_expired?).to be true
    end
  end

  describe "#has_completed_registration?" do
    context "when the password, name and mobile number are missing" do
      let(:user) { build_stubbed(:user, password: nil, name: nil, mobile_number: nil) }

      it "is false" do
        expect(user.has_completed_registration?).to be false
      end
    end

    context "when the password, name and mobile number have all been set" do
      let(:user) { build_stubbed(:user) }

      it "is true" do
        expect(user.has_completed_registration?).to be true
      end
    end
  end

  describe "#mark_as_deleted!" do
    it "sets the user 'deleted_at' timestamp to the current time" do
      user = create(:user)
      freeze_time do
        expect { user.mark_as_deleted! }.to change { user.deleted_at }.from(nil).to(Time.zone.now)
      end
    end

    it "sets the user 'deleted_by' to id of the user that made the deletion if supplied" do
      user = create(:user)
      deletor = create(:user)
      freeze_time do
        expect { user.mark_as_deleted!(deletor) }.to change { user.deleted_by }.from(nil).to(deletor.id)
      end
    end

    it "sets the user 'account_activated' to false" do
      user = create(:user, :activated)

      freeze_time do
        expect { user.mark_as_deleted! }.to change { user.account_activated }.from(true).to(false)
      end
    end

    it "does not change the flag if was already enabled" do
      user = create(:user, :deleted)
      expect { user.mark_as_deleted! }.not_to change(user, :deleted_at)
    end

    it "sets invitation_token to nil" do
      user = create(:user, :activated, invitation_token: "xyz")
      expect { user.mark_as_deleted! }.to change { user.invitation_token }.from("xyz").to(nil)
    end
  end

  describe "#deleted?" do
    it "returns true for users with deleted timestamp" do
      user = create(:user, :deleted)
      expect(user).to be_deleted
    end

    it "returns false for users without deleted timestamp" do
      user = create(:user)
      expect(user).not_to be_deleted
    end
  end

  describe "#mobile_number_change_allowed?" do
    it "is allowed for users that haven't verified their mobile number" do
      user = build_stubbed(:user, mobile_number_verified: false)
      expect(user).to be_mobile_number_change_allowed
    end

    it "is not allowed for users that have verified their mobile number" do
      user = build_stubbed(:user, mobile_number_verified: true)
      expect(user).not_to be_mobile_number_change_allowed
    end
  end

  describe "#reset_to_invited_state!" do
    it "sets deleted_at to nil" do
      user = create(:user, :deleted)
      expect { user.reset_to_invited_state! }.to change { user.deleted_at }.from(user.deleted_at).to(nil)
    end

    it "sets account_activated to false" do
      user = create(:user, :activated)
      expect { user.reset_to_invited_state! }.to change { user.account_activated }.from(true).to(false)
    end

    it "sets mobile_number_verified to false" do
      user = create(:user, :activated)
      expect { user.reset_to_invited_state! }.to change { user.mobile_number_verified }.from(true).to(false)
    end

    it "sets has_accepted_declaration to false" do
      user = create(:user, :activated)
      expect { user.reset_to_invited_state! }.to change { user.has_accepted_declaration }.from(true).to(false)
    end

    it "sets has_been_sent_welcome_email to false" do
      user = create(:user, :activated)
      expect { user.reset_to_invited_state! }.to change { user.has_been_sent_welcome_email }.from(true).to(false)
    end

    it "sets has_viewed_introduction to false" do
      user = create(:user, :activated)
      expect { user.reset_to_invited_state! }.to change { user.has_viewed_introduction }.from(true).to(false)
    end

    it "sets name to blank" do
      user = create(:user, :activated, name: "A User")
      expect { user.reset_to_invited_state! }.to change { user.name }.from("A User").to("")
    end

    it "sets name to nil" do
      user = create(:user, :activated, mobile_number: "07777777777")
      expect { user.reset_to_invited_state! }.to change { user.mobile_number }.from("07777777777").to(nil)
    end
  end

  describe "#has_role?" do
    subject(:user) { create(:user, team:, organisation: team.organisation, roles: user_roles) }

    let(:team) { create(:team, roles: team_roles) }
    let(:team_roles) { [] }

    context "when the user has no roles" do
      let(:user_roles) { [] }

      it "returns false" do
        expect(user).not_to have_role("test")
      end

      context "when the team roles include the specified role" do
        let(:team_roles) { %w[test] }

        it "returns true" do
          expect(user).to have_role("test")
        end
      end

      context "when the team roles do not include the specified role" do
        let(:team_roles) { %w[another_role] }

        it "returns false" do
          expect(user).not_to have_role("test")
        end
      end
    end

    context "when the user has roles" do
      context "when the user roles include the specified role" do
        let(:user_roles) { %w[test] }

        it "returns true" do
          expect(user).to have_role("test")
        end
      end

      context "when the user roles do not include the specified role" do
        let(:user_roles) { %w[another_role] }

        it "returns false" do
          expect(user).not_to have_role("test")
        end

        context "when the team roles include the specified role" do
          let(:team_roles) { %w[test] }

          it "returns true" do
            expect(user).to have_role("test")
          end
        end

        context "when the team roles do not include the specified role" do
          let(:team_roles) { %w[another_role] }

          it "returns false" do
            expect(user).not_to have_role("test")
          end
        end
      end
    end
  end

  describe ".inactive" do
    subject(:users) { described_class.inactive }

    let!(:user) { create(:user, trait, last_sign_in_at:) }
    let(:trait) { :activated }

    context "when last_sign_in_at is nil" do
      let(:last_sign_in_at) { nil }

      it "is not included in the results" do
        expect(users).not_to include(user)
      end
    end

    context "when last_sign_in_at is within 3 months" do
      let(:last_sign_in_at) { 2.months.ago }

      it "is not included in the results" do
        expect(users).not_to include(user)
      end
    end

    context "when last_sign_in_at is more than 3 months ago" do
      let(:last_sign_in_at) { 4.months.ago }

      context "when user is activated" do
        it "is included in the results" do
          expect(users).to include(user)
        end
      end

      context "when user is deleted" do
        let(:trait) { :deleted }

        it "is not included in the results" do
          expect(users).not_to include(user)
        end
      end

      context "when user is not activated" do
        let(:trait) { :inactive }

        it "is not included in the results" do
          expect(users).not_to include(user)
        end
      end
    end
  end

  describe ".lock_inactive_users!", :with_stubbed_mailer do
    let!(:inactive_user) { create(:user, :activated, last_sign_in_at: 5.months.ago) }
    let!(:active_user) { create(:user, :activated, last_sign_in_at: 1.day.ago) }
    let!(:invited_user) { create(:user, :invited) }

    before { described_class.lock_inactive_users! }

    it "locks inactive users" do
      expect(inactive_user.reload).to be_access_locked
    end

    it "sets the locked reason" do
      expect(inactive_user.reload.locked_reason).to eq(described_class.locked_reasons[:inactivity])
    end

    it "does not lock active users" do
      expect(active_user.reload).not_to be_access_locked
    end

    it "does not lock invited users" do
      expect(invited_user.reload).not_to be_access_locked
    end

    it "does not send emails with unlock instructions immediately" do
      expect(delivered_emails).to be_empty
    end
  end

  describe "#send_unlock_instructions", :with_stubbed_mailer do
    subject(:user) { create(:user, :activated, :locked) }

    before { user.send_unlock_instructions }

    it "populates the unlock token" do
      expect(user.reload.unlock_token).not_to be_nil
    end

    it "populates the reset password token" do
      expect(user.reload.reset_password_token).not_to be_nil
    end

    it "sends the email" do
      expect(delivered_emails.last.template).to eq NotifyMailer::TEMPLATES[:account_locked]
    end
  end

  describe "#send_unlock_instructions_after_inactivity", :with_stubbed_mailer do
    subject(:user) { create(:user, :activated) }

    before { user.send_unlock_instructions_after_inactivity }

    it "populates the unlock token" do
      expect(user.reload.unlock_token).not_to be_nil
    end

    it "sends the email" do
      expect(delivered_emails.last.template).to eq NotifyMailer::TEMPLATES[:account_locked_inactive]
    end
  end

  describe "#lock_access!", :with_stubbed_mailer do
    subject(:user) { create(:user, :activated) }

    context "with no reason supplied" do
      before { user.lock_access! }

      it "defaults to failed_attempts" do
        expect(user.reload.locked_reason).to eq(described_class.locked_reasons[:failed_attempts])
      end

      it "sends the email" do
        expect(delivered_emails.last.template).to eq NotifyMailer::TEMPLATES[:account_locked]
      end
    end

    context "with reason failed_attempts" do
      before { user.lock_access!(reason: :failed_attempts) }

      it "saves the reason" do
        expect(user.reload.locked_reason).to eq(described_class.locked_reasons[:failed_attempts])
      end

      it "sends the email" do
        expect(delivered_emails.last.template).to eq NotifyMailer::TEMPLATES[:account_locked]
      end
    end

    context "with reason inactivity" do
      before { user.lock_access!(reason: :inactivity) }

      it "saves the reason" do
        expect(user.reload.locked_reason).to eq(described_class.locked_reasons[:inactivity])
      end

      it "does not send the email" do
        expect(delivered_emails).to be_empty
      end
    end
  end
end
