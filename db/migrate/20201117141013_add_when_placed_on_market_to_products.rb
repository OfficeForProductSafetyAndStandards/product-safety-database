class AddWhenPlacedOnMarketToProducts < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE when_placed_on_markets AS ENUM ('before_2021', 'on_or_after_2021', 'unknown_date');" }
        dir.down { execute "DROP TYPE IF EXISTS when_placed_on_markets;" }
      end
      add_column :products, :when_placed_on_market, :when_placed_on_markets
    end
  end
end
