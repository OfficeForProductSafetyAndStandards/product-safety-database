class AddWelcomeFlipper < ActiveRecord::Migration[7.1]
  def up
    Flipper.enable(:welcome)
  end

  def down
    Flipper.disable(:welcome)
    # Flipper.remove(:welcome)
    # This will remove the Flipper, but you should disable it first.
  end
end
