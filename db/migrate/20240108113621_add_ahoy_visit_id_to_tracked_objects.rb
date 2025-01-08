class AddAhoyVisitIdToTrackedObjects < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :investigations, :ahoy_visit, index: { algorithm: :concurrently }
    add_reference :products, :ahoy_visit, index: { algorithm: :concurrently }
  end
end
