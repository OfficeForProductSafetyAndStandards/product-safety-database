class AddCoronavirusRelatedToInvestigations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :investigations, :coronavirus_related, :boolean, default: false
    end
  end
end
