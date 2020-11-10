class AddAuthenticitiesEnumToProducts < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      reversible do |dir|
        dir.up { execute "CREATE TYPE authenticities AS ENUM ('counterfeit', 'genuine', 'unsure');" }
        dir.down { execute "DROP TYPE IF EXISTS authenticities;" }
      end
      add_column :products, :authenticity, :authenticities
    end
  end
end
