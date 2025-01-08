class ChangeHasOnlineRecallInformationToCorrectiveActions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE has_online_recall_information AS ENUM ('has_online_recall_information_yes', 'has_online_recall_information_no', 'has_online_recall_information_not_relevant');" }
        dir.down { execute "DROP TYPE IF EXISTS has_online_recall_information;" }
      end

      change_table :corrective_actions, bulk: true do |t|
        t.column :has_online_recall_information, :has_online_recall_information, default: nil
      end
    end
  end
end
