class AddNotifyingCountryToInvestigations < ActiveRecord::Migration[6.1]
  def change
    add_column :investigations, :notifying_country, :string
  end
end
