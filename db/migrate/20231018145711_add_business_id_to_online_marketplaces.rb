class AddBusinessIdToOnlineMarketplaces < ActiveRecord::Migration[7.0]
  def change
    add_column :online_marketplaces, :business_id, :bigint
  end
end
