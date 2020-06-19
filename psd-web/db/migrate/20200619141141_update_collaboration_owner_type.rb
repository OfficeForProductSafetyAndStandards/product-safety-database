class UpdateCollaborationOwnerType < ActiveRecord::Migration[5.2]
  def change
    Collaboration.where(type: "Collaboration::OwnerTeam").update_all(type: "Collaboration::Access::OwnerTeam")
    Collaboration.where(type: "Collaboration::OwnerUser").update_all(type: "Collaboration::Access::OwnerUser")
  end
end
