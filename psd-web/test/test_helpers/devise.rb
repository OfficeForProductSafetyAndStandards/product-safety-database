module TestHelpers
  module Devise
    def sign_out
      return if page.has_css?("a", text: "Sign in to your account")

      click_on "Sign out", match: :first
    end

    def sign_in(user = users(:opss))
      visit root_path
      click_on "Sign in to your account"

      fill_in "user[email]", with: user.email
      fill_in "user[password]", with: "password"
      click_on "Continue"

      user
    end
  end
end
