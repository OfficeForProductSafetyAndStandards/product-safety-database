require "rails_helper"

RSpec.describe InviteUserToTeam, :with_stubbed_mailer, :with_test_queue_adapter do
  describe ".call" do
    subject(:result) { described_class.call(params) }

    let(:email) { Faker::Internet.email }
    let(:team) { create(:team) }
    let(:inviting_user) { create(:user, :activated, team:) }

    context "when there is no existing user" do
      let(:params) { { email:, team: } }
      let(:new_token) { "new_token" }

      before do
        allow(SecureRandom).to receive(:hex).with(15).and_return(:new_token)
      end

      it "creates the user" do
        expect { result }.to change(User, :count).by(1)
      end

      it "sets the user in the context" do
        expect(result.user).to be_a(User)
      end

      it "sets the correct user properties", :aggregate_failures do
        expect(result.user).to have_attributes(
          email:,
          organisation: team.organisation,
          invitation_token: new_token,
          invited_at: kind_of(Time),
          team:
        )
      end

      it "enqueues the SendUserInvitationJob with the new user ID", :aggregate_failures do
        expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
          expect(recipient_id).to eq result.user.id
          expect(inviting_user_id).to be_nil
        end
      end

      context "with inviting_user parameter" do
        let(:params) { { email:, team:, inviting_user: } }

        it "enqueues the SendUserInvitationJob with the new user ID and inviting user ID", :aggregate_failures do
          expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
            expect(recipient_id).to eq result.user.id
            expect(inviting_user_id).to inviting_user.id
          end
        end
      end
    end

    context "when there is an existing user" do
      let!(:existing_user) { create(:user, email:, team: existing_user_team, invitation_token:, invited_at:) }
      let(:existing_user_team) { team }
      let(:invitation_token) { "test" }
      let(:invited_at) { Time.zone.now }

      context "with email parameter" do
        let(:params) { { email:, team: } }

        context "when the existing user is already on the same team" do
          it "enqueues the SendUserInvitationJob with the existing user ID", :aggregate_failures do
            expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
              expect(recipient_id).to eq existing_user.id
              expect(inviting_user_id).to be_nil
            end
          end

          context "when the user is deleted" do
            before do
              existing_user.mark_as_deleted!
            end

            it "enqueues the SendUserInvitationJob with the existing user ID", :aggregate_failures do
              expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
                expect(recipient_id).to eq existing_user.id
                expect(inviting_user_id).to be_nil
              end
            end

            it "resets user to the state that it was in when initially invited" do
              result
              expect_user_to_have_been_reset_to_invited_state(existing_user)
            end
          end

          context "when the email supplied is in a different case to the existing user" do
            let(:email) { "TEst@example.com" }

            it "enqueues the SendUserInvitationJob with the existing user ID", :aggregate_failures do
              expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
                expect(recipient_id).to eq existing_user.id
                expect(inviting_user_id).to be_nil
              end
            end
          end
        end

        context "when the existing user is on a different team" do
          let(:existing_user_team) { create(:team) }

          context "when the user is deleted" do
            before do
              existing_user.mark_as_deleted!
            end

            # rubocop:disable RSpec/MultipleExpectations
            it "reassigns user to new team and enqueues the SendUserInvitationJob with the existing user ID" do
              expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
                expect(recipient_id).to eq existing_user.id
                expect(inviting_user_id).to be_nil
              end

              expect(existing_user.reload.team).to eq team
              # rubocop:enable RSpec/MultipleExpectations
            end

            it "resets user to the state that it was in when initially invited" do
              result
              expect_user_to_have_been_reset_to_invited_state(existing_user)
            end
          end

          context "when the user is not deleted" do
            it "raises a ActiveRecord::RecordInvalid exception" do
              expect { result }.to raise_error(ActiveRecord::RecordInvalid)
            end
          end
        end
      end

      context "with user parameter" do
        let(:params) { { user: existing_user, team: } }

        context "when the existing user has no invitation token" do
          let(:invitation_token) { nil }
          let(:new_token) { "new_token" }

          before do
            allow(SecureRandom).to receive(:hex).with(15).and_return(:new_token)
          end

          it "sets the invitation token" do
            expect { result }.to change(existing_user, :invitation_token).from(nil).to(new_token)
          end
        end

        context "when the existing user has an invitation token" do
          it "does not change the invitation token" do
            expect { result }.not_to change(existing_user, :invitation_token)
          end
        end

        context "when the existing user was invited less than an hour ago" do
          let(:invited_at) { Time.zone.now - 10.minutes }

          it "does not update the user's invited_at" do
            expect { result }.not_to change(existing_user, :invited_at)
          end
        end

        context "when the existing user was invited more than an hour ago" do
          let(:invited_at) { Time.zone.now - 2.hours }

          it "updates the user's invited_at" do
            expect { result }.to change(existing_user, :invited_at)
          end
        end

        context "with inviting_user parameter" do
          let(:params) { { user: existing_user, team:, inviting_user: } }

          it "enqueues the SendUserInvitationJob with the inviting user ID", :aggregate_failures do
            expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
              expect(recipient_id).to eq existing_user.id
              expect(inviting_user_id).to inviting_user_id
            end
          end
        end

        context "with no inviting_user parameter" do
          let(:params) { { user: existing_user, team: } }

          it "enqueues the SendUserInvitationJob with nil inviting user ID", :aggregate_failures do
            expect { result }.to have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |recipient_id, inviting_user_id|
              expect(recipient_id).to eq existing_user.id
              expect(inviting_user_id).to be_nil
            end
          end
        end
      end
    end

    context "with no team parameter" do
      let(:params) { { email: } }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user or email parameter" do
      let(:params) { { team: } }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no parameters" do
      let(:params) { nil }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    def expect_user_to_have_been_reset_to_invited_state(existing_user)
      existing_user.reload
      expect(existing_user.name).to eq ""
      expect(existing_user.deleted_at).to eq nil
      expect(existing_user.account_activated).to eq false
      expect(existing_user.mobile_number_verified).to eq false
      expect(existing_user.has_accepted_declaration).to eq false
      expect(existing_user.has_been_sent_welcome_email).to eq false
      expect(existing_user.has_viewed_introduction).to eq false
      expect(existing_user.mobile_number).to eq nil
    end
  end
end
