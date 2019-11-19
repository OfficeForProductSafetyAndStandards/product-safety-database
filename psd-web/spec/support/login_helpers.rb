module LoginHelpers
  def sign_in(as_user: build(:user))
    allow_any_instance_of(ApplicationController).to receive(:access_token).and_return("test")
    allow(KeycloakClient.instance).to receive(:user_signed_in?).with("test").and_return(true)
    allow(KeycloakClient.instance).to receive(:user_info).and_return(format_user_for_get_userinfo(as_user))

    allow(KeycloakClient.instance).to receive(:get_user_roles).with(as_user.id).and_return([:psd_user])
  end

private

  def format_user_for_get_userinfo(user, groups: [])
    { id: user.id, email: user.email, name: user.name }
  end
end
