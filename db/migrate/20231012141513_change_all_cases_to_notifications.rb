class ChangeAllCasesToNotifications < ActiveRecord::Migration[7.0]
  def self.up
    Investigation.where(type: "Investigation::Case").update_all(type: "Investigation::Notification")
  end

  def self.down
    Investigation.where(type: "Investigation::Notification").update_all(type: "Investigation::Case")
  end
end
