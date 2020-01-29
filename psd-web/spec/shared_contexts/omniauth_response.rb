RSpec.shared_context "omniauth response" do
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
end
