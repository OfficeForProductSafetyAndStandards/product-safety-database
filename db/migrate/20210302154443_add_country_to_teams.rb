class AddCountryToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :country, :string
  end
end
