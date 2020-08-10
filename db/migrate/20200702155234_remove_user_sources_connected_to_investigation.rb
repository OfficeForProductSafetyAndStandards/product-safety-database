class RemoveUserSourcesConnectedToInvestigation < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      UserSource.where(sourceable_type: "Investigation").delete_all
    end
  end
end
