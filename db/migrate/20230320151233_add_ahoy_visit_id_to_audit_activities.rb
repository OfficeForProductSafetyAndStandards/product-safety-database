class AddAhoyVisitIdToAuditActivities < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :activities, :ahoy_visit, index: { algorithm: :concurrently }
  end
end
