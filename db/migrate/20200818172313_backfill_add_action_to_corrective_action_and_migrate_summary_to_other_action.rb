class BackfillAddActionToCorrectiveActionAndMigrateSummaryToOtherAction < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    CorrectiveAction.unscoped.in_batches do |relation|
      relation.update_all action: "other"
      sleep(0.01)
    end
  end
end
