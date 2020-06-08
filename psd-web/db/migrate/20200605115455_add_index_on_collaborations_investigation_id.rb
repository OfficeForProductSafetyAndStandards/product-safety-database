class AddIndexOnCollaborationsInvestigationId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :collaborations, :investigation_id, algorithm: :concurrently
  end
end
