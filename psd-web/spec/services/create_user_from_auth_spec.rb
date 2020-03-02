require "rails_helper"
require "shared_contexts/omniauth_response"
require "shared_examples/create_user"

RSpec.describe CreateUserFromAuth do
  include_context "with omniauth response"

  subject(:create_user_service) { described_class.new(omniauth_response) }

  describe "#user" do
    context "when the user does not exist" do
      context "when belonging to an existing team" do
        it_behaves_like "creates a user"
      end

      context "when not belonging to an existing team" do
        context "when belonging to an existing organisation" do
          let(:group) { organisation.path }

          it_behaves_like "creates a user"
        end

        context "when not belonging to an existing organisation" do
          let(:group) { Faker::Hipster.word }

          it "raises a RuntimeError" do
            expect { create_user_service.user }.to raise_error(RuntimeError, "No organisation found")
          end
        end
      end
    end

    context "when the user exists" do
      before { create(:user, id: uid) }

      it "updates the organisation" do
        expect { create_user_service.user }.not_to change(User, :count)
      end
    end
  end
end
