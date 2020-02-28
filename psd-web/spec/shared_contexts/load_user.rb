RSpec.shared_context "with mock user" do
  let(:user)              { instance_double(User) }
  let(:user_service)      { instance_double(CreateUserFromAuth, user: user) }
  let(:omniauth_response) { double }
end
