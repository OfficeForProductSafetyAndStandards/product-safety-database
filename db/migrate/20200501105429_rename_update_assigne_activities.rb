class Activity < ApplicationRecord; end

class RenameUpdateAssigneActivities < ActiveRecord::Migration[5.2]
  def up
    Activity.where(type: "AuditActivity::Investigation::UpdateAssignee").update_all(type: "AuditActivity::Investigation::UpdateOwner")
    Activity.where(type: "AuditActivity::Investigation::AutomaticallyReassign").update_all(type: "AuditActivity::Investigation::AutomaticallyUpdateOwner")
  end

  def down
    Activity.where(type: "AuditActivity::Investigation::UpdateOwner").update_all(type: "AuditActivity::Investigation::UpdateAssignee")
    Activity.where(type: "AuditActivity::Investigation::AutomaticallyUpdateOwner").update_all(type: "AuditActivity::Investigation::AutomaticallyReassign")
  end
end
