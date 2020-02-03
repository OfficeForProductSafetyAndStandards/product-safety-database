require "rails_helper"
require "shared_contexts/omniauth_response"
require "shared_examples/create_user"

RSpec.describe CreateUserFromAuth do
  include_context "omniauth response"

  subject { described_class.new(omniauth_response) }

  describe "#user" do
    context "when the user does not exists" do
      context "when belonging to an existing team" do
        it_behaves_like "creates a user for"
      end

      context "when not belonging to an existing team" do
        context "when belonging to an existing organisation" do
          let(:group) { organisation.path }

          it_behaves_like "creates a user for"
        end

        context "when not belonging to an existing organisation" do
          let(:group) { Faker::Hipster.word }

          it "raises a RuntimeError" do
            expect { subject.user }.to raise_error(RuntimeError, "No organisation found")
          end
        end
      end
    end

    context "when the user exists" do
      before { create(:user, id: uid) }

      it "updates the organisation" do
        expect { subject.user }.to_not change(User, :count)
      end
    end
  end
end
