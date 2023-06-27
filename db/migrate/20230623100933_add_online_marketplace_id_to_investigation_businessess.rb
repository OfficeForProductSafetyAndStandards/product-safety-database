class AddOnlineMarketplaceIdToInvestigationBusinessess < ActiveRecord::Migration[7.0]
  def change
    add_column :investigation_businesses, :online_marketplace_id, :integer
  end
end
