# This migration comes from prism (originally 20231124151610)
class AddMoreFieldsToPrismEvaluations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_evaluations, bulk: true do |t|
        t.text :factors_to_take_into_account_details
        t.string :featured_in_media
      end
    end
  end
end
