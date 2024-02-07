class RemoveEnums < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      change_column :users, :locked_reason, :string
      change_column :investigation_products, :affected_units_status, :string
      change_column :products, :authenticity, :string
      change_column :products, :has_markings, :string
      change_column :corrective_actions, :has_online_recall_information, :string
      change_column :investigations, :reported_reason, :string
      change_column :investigations, :risk_level, :string
      change_column :risk_assessments, :risk_level, :string
      change_column :unexpected_events, :severity, :string
      change_column :unexpected_events, :usage, :string
      change_column :products, :when_placed_on_market, :string

      drop_enum :account_locked_reasons
      drop_enum :affected_units_statuses
      drop_enum :authenticities
      drop_enum :has_markings_values
      drop_enum :has_online_recall_information
      drop_enum :reported_reasons
      drop_enum :risk_levels
      drop_enum :severities
      drop_enum :usages
      drop_enum :when_placed_on_markets
    end
  end

  def down
    safety_assured do
      create_enum :account_locked_reasons, %w[failed_attempts inactivity]
      create_enum :affected_units_statuses, %w[exact approx unknown not_relevant]
      create_enum :authenticities, %w[counterfeit genuine unsure]
      create_enum :has_markings_values, %w[markings_yes markings_no markings_unknown]
      create_enum :has_online_recall_information, %w[has_online_recall_information_yes has_online_recall_information_no has_online_recall_information_not_relevant]
      create_enum :reported_reasons, %w[unsafe non_compliant unsafe_and_non_compliant safe_and_compliant]
      create_enum :risk_levels, %w[serious high medium low other not_conclusive]
      create_enum :severities, %w[serious high medium low unknown_severity other]
      create_enum :usages, %w[during_normal_use during_misuse with_adult_supervision without_adult_supervision unknown_usage]
      create_enum :when_placed_on_markets, %w[before_2021 on_or_after_2021 unknown_date]

      change_column :users, :locked_reason, :enum, enum_type: "account_locked_reasons"
      change_column :investigation_products, :affected_units_status, :enum, enum_type: "affected_units_statuses"
      change_column :products, :authenticity, :enum, enum_type: "authenticities"
      change_column :products, :has_markings, :enum, enum_type: "has_markings_values"
      change_column :corrective_actions, :has_online_recall_information, :enum, enum_type: "has_online_recall_information"
      change_column :investigations, :reported_reason, :enum, enum_type: "reported_reasons"
      change_column :investigations, :risk_level, :enum, enum_type: "risk_levels"
      change_column :risk_assessments, :risk_level, :enum, enum_type: "risk_levels"
      change_column :unexpected_events, :severity, :enum, enum_type: "severities"
      change_column :unexpected_events, :usage, :enum, enum_type: "usages"
      change_column :products, :when_placed_on_market, :enum, enum_type: "when_placed_on_markets"
    end
  end
end
