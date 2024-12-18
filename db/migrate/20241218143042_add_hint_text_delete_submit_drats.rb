class AddHintTextDeleteSubmitDrafts < ActiveRecord::Migration[7.1]
  def up
    Flipper.enable(:hint_text_delete_submit_drafts)
  end

  def down
    Flipper.disable(:hint_text_delete_submit_drafts)
    # Flipper.remove(:hint_text_delete_submit_drafts)
    # This will remove the Flipper, but you should disable it first.
  end
end
