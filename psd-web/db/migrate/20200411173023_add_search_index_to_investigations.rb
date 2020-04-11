class AddSearchIndexToInvestigations < ActiveRecord::Migration[5.2]
  def change
    add_column :investigations, :search_index, :tsvector
  end
end
