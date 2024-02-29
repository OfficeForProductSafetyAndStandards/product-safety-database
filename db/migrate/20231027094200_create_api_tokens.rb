class CreateApiTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :api_tokens do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :token
      t.string :name
      t.jsonb :metadata, default: {}
      t.boolean :transient, default: false
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps
    end
    add_index :api_tokens, :token, unique: true
  end
end
