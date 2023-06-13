class AddOpssFundingInfoFieldsToTests < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :tests, bulk: true do |t|
        t.string :tso_certificate_reference_number
        t.date :tso_certificate_issue_date
      end
    end
  end
end
