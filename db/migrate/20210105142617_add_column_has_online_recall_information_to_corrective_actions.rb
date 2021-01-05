class AddColumnHasOnlineRecallInformationToCorrectiveActions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :corrective_actions, :has_online_recall_information, :boolean
    end
  end
end
