class CreateTeamsUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :teams_users do |t|
      t.belongs_to :team, type: :uuid
      t.belongs_to :user, type: :uuid
    end
  end
end
