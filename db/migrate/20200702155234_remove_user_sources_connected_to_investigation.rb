class RemoveUserSourcesConnectedToInvestigation < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      # NOTE: UserSource was removed in https://github.com/OfficeForProductSafetyAndStandards/product-safety-database/pull/2051
      # This was an irreversable migration for one time use but is kept for now to ensure it can be reversed
      if defined?(UserSource)
        UserSource.where(sourceable_type: "Investigation").delete_all
      end
    end
  end
end
