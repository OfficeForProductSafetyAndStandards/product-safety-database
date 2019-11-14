class CreateUsers < ActiveRecord::Migration[5.2]
  class User < ApplicationRecord; end
  class UserAttributes < ApplicationRecord; end

  def up
    create_table :users, id: "uuid", default: nil do |t|
      t.string :name
      t.string :email
      t.boolean :has_accepted_declaration, default: false
      t.boolean :has_been_sent_welcome_email, default: false
      t.boolean :has_viewed_introduction, default: false
      t.belongs_to :organisation, type: :uuid
      t.timestamps

      t.index :email
      t.index :name
    end

    UserAttributes.all.each do |user|
      User.create(
        id: user.user_id,
        has_accepted_declaration: user.has_accepted_declaration,
        has_been_sent_welcome_email: user.has_been_sent_welcome_email,
        has_viewed_introduction: user.has_viewed_introduction,
      )
    end

    drop_table :user_attributes
  end

  def down
    create_table :user_attributes, primary_key: "user_id", id: "uuid", default: nil do |t|
      t.boolean :has_accepted_declaration, default: false
      t.boolean :has_been_sent_welcome_email, default: false
      t.boolean :has_viewed_introduction, default: false
      t.timestamps

      t.index :user_id
    end

    User.all.each do |user|
      UserAttributes.create(
        user_id: user.id,
        has_accepted_declaration: user.has_accepted_declaration,
        has_been_sent_welcome_email: user.has_been_sent_welcome_email,
        has_viewed_introduction: user.has_viewed_introduction,
      )
    end

    drop_table :users
  end
end
