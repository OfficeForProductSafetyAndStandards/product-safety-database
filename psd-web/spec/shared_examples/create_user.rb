RSpec.shared_examples "creates a user" do
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
