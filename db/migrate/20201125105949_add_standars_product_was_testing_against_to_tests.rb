class AddStandarsProductWasTestingAgainstToTests < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      # TODO: add default to empty array in later migration
      add_column :tests, :standards_product_was_tested_against, :string, array: true
    end
  end
end
