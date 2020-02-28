RSpec.shared_context "with mock user" do
  let(:user)              { double(User) }
  let(:user_service)      { instance_double(CreateUserFromAuth, user: user) }
  let(:omniauth_response) { double }
end
