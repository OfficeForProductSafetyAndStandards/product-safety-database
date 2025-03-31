class AddTwoFactorAuthenticationFlipper < ActiveRecord::Migration[7.1]
  def up
    # Enable the feature by default
    Flipper.enable(:two_factor_authentication)
  end

  def down
    # Disable the feature when rolling back
    Flipper.disable(:two_factor_authentication)
  end
end
