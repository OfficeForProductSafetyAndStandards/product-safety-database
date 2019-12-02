module LoginHelpers
  def sign_in(as_user: build(:user))
    allow_any_instance_of(ApplicationController).to receive(:access_token).and_return(access_token)
    allow(KeycloakClient.instance).to receive(:user_signed_in?).with(access_token).and_return(true)
    allow(KeycloakClient.instance).to receive(:user_info).and_return(format_user_for_get_userinfo(as_user))
    allow(KeycloakClient.instance).to receive(:get_user_roles).with(as_user.id).and_return(as_user.roles)
  end

private

  def format_user_for_get_userinfo(user)
    { id: user.id, email: user.email, name: user.name }
  end

  def access_token
    "test"
  end
end

RSpec.configure do |config|
  config.include LoginHelpers
end
