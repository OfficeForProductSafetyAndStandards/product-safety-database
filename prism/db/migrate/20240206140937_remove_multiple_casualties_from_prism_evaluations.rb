class RemoveMultipleCasualtiesFromPrismEvaluations < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :prism_evaluations, :multiple_casualties, :boolean
    end
  end
end
