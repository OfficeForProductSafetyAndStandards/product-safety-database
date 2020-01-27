require "rails_helper"

RSpec.describe CreateUserFromAuth do
  let(:omniauth_response) do
    {
      "provider" => :openid_connect,
      "uuid" => SecureRandom.uuid,
      "info" => {
        "name" => Faker::Name.name,
        "email" =>"user@example.com"
      },
      "extra" => {
        "raw_info" => {
          "groups" => [Faker::Quote.matz]
        }
      }
    }
  end

  subject { described_class.new(omniauth_response) }

  describe "#user" do

    context "when the user does not exists" do
      context "when belonging to an existing team" do
        it "creates the user" do

        end
      end

      context "when belonging to an existing team" do
        context "when belonging to an existing organisation" do
          it "creates the user" do
          end
        end

        context "when not belonging to an existing organisation" do
          it "raises a RuntimeError" do
          end
        end
      end
    end

    context "when the user exists" do
      context "when belonging to another organistion" do
        it "updates the organisation" do
        end
      end
    end

  end
end
