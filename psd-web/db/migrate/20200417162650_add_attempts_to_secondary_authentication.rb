class AddAttemptsToSecondaryAuthentication < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :secondary_authentications, :attempts, :integer, default: 0
    end
  end
end
