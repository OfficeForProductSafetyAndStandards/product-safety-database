class RenameEditAccessToAccessEdit < ActiveRecord::Migration[5.2]
  def change
    Collaboration.where(type: "Collaboration::EditAcess").update_all(type: "Collaboration::Access::Edit")
  end
end
