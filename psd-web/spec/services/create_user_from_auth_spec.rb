require "rails_helper"

RSpec.shared_examples "user creator" do
  it "creates the user" do
    expect {
      subject.user
    }.to change {
      User.where(
        id:    omniauth_response["uid"],
        email: omniauth_response["info"]["email"],
        name:  omniauth_response["info"]["name"]
      ).count
    }.from(0).to(1)
  end
end

RSpec.describe CreateUserFromAuth do
  let!(:organisation) { create :organisation }
  let!(:team)         { create :team, organisation: organisation }
  let(:uid) { SecureRandom.uuid }
  let(:group) { team.path }
  let(:omniauth_response) do
    {
      "provider" => :openid_connect,
      "uid" => uid,
      "info" => {
        "name" => Faker::Name.name,
        "email" => "user@example.com"
      },
      "extra" => {
        "raw_info" => {
          "groups" => [group]
        }
      }
    }
  end

  subject { described_class.new(omniauth_response) }

  describe "#user" do
    context "when the user does not exists" do
      context "when belonging to an existing team" do
        it_behaves_like "user creator"
      end

      context "when not belonging to an existing team" do
        context "when belonging to an existing organisation" do
          let(:group) { organisation.path }

          it_behaves_like "user creator"
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
