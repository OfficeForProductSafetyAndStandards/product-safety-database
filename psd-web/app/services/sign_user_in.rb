class SignUserIn
  include ActiveModel::Model
  include ActiveModel::Attributes
  attribute :email
  attribute :password

  validates :email, email: { message: "Enter your email address in the correct format, like name@example.com" }
  validates_presence_of :email, message: "Enter your email address"
  validates_presence_of :password, message: "Enter your password"

private

  attr_accessor :email, :password
end
