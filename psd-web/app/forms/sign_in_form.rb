class SignInForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :password

  validates :email,
            email: {
              message: I18n.t(:wrong_email_or_password, scope: "sign_in_form.email"),
              if: ->(sign_in_form) { sign_in_form.email.present? }
            }
  validates_presence_of :email, message: "Enter your email address"
  validates_presence_of :password, message: "Enter your password"
end
