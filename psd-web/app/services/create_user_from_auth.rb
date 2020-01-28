class CreateUserFromAuth

  def initialize(omniauth_response)
    self.omniauth_response = omniauth_response
  end

  def user
    @user ||= begin

    end
  end

  private

  attr_accessor :omniauth_response
end
