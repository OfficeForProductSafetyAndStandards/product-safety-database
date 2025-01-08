class AddOnlineRecallInformationToCorrectiveActions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :corrective_actions, :online_recall_information, :string
    end
  end
end
