class SignInForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :password

  validates :email,
            email: {
              message: "Enter your email address in the correct format, like name@example.com",
              if: ->(sign_in_form) { sign_in_form.email.present? }
            }
  validates_presence_of :email, message: "Enter your email address"
  validates_presence_of :password, message: "Enter your password"
end
