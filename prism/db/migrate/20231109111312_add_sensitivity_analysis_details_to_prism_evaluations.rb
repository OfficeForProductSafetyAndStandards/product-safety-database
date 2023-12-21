class AddSensitivityAnalysisDetailsToPrismEvaluations < ActiveRecord::Migration[7.0]
  def change
    add_column :prism_evaluations, :sensitivity_analysis_details, :text
  end
end
