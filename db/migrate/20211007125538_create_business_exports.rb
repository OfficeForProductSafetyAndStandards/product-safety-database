class CreateBusinessExports < ActiveRecord::Migration[6.1]
  def change
    create_table :business_exports do |t|

      t.timestamps
    end
  end
end
