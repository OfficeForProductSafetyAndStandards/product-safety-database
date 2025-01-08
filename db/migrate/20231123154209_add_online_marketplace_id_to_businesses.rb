class AddOnlineMarketplaceIdToBusinesses < ActiveRecord::Migration[7.0]
  def change
    add_column :businesses, :online_marketplace_id, :bigint
  end
end
