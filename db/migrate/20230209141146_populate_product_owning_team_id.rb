class PopulateProductOwningTeamId < ActiveRecord::Migration[7.0]
  def up
    sql = "UPDATE products p
    SET owning_team_id = c.collaborator_id
    FROM investigation_products ip
    JOIN investigations i ON ip.investigation_id = i.id
    JOIN collaborations c ON i.id = c.investigation_id
    AND c.type = 'Collaboration::Access::OwnerTeam'
    WHERE p.id = ip.product_id
    AND i.is_closed = false
    AND p.owning_team_id IS NULL;"

    ApplicationRecord.connection.exec_update(sql)
  end
end
