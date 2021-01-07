class FixAttachmentNameFromCorrectiveActions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          ActiveStorage::Attachment.where(record_type: "CorrectiveAction", name: "documents").update_all(name: "document")
        end
        dir.down do
          ActiveStorage::Attachment.where(record_type: "CorrectiveAction", name: "document").update_all(name: "documents")
        end
      end
    end
  end
end
