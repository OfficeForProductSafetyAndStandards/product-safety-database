class UserRole < ApplicationRecord; end

class RemovePsdUserRoles < ActiveRecord::Migration[6.0]
  def up
    UserRole.where(name: "psd_user").delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
