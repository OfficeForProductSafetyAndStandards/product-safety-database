class PopulateProductOwningTeamId < ActiveRecord::Migration[7.0]
  def up
    sql = "UPDATE products 
    SET owning_team_id = c.collaborator_id 
    FROM collaborations c 
    INNER JOIN investigation_products ON c.investigation_id = investigation_products.investigation_id 
    INNER JOIN investigations ON investigation_products.investigation_id = investigations.id 
    WHERE c.type = 'Collaboration::Access::OwnerTeam' 
    AND investigations.is_closed = false 
    AND products.owning_team_id IS NULL;"

    ApplicationRecord.connection.exec_update(sql)
  end
end
