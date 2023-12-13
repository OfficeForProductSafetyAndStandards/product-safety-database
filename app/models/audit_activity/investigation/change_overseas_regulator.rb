class AuditActivity::Investigation::ChangeOverseasRegulator < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:is_from_overseas_regulator, :overseas_regulator_country)

    {
      updates: updated_values
    }
  end

  def title(*)
    "Overseas regulator changed"
  end

  def body
    if previous_from_overseas_regulator.nil? && previous_country == "None"
      "Overseas regulator set to #{country_from_code(new_country)}"
    else
      "Overseas regulator changed from #{country_from_code(previous_country)} to #{country_from_code(new_country)}"
    end
  end

  def previous_from_overseas_regulator
    metadata["updates"]["is_from_overseas_regulator"]&.first
  end

  def new_from_overseas_regulator
    metadata["updates"]["is_from_overseas_regulator"]&.second
  end

  def previous_country
    metadata["updates"]["overseas_regulator_country"]&.first || "None"
  end

  def new_country
    metadata["updates"]["overseas_regulator_country"]&.second || "None"
  end

private

  def country_from_code(code)
    country = Country.overseas_countries.find { |c| c[1] == code }
    (country && country[0]) || code
  end
end
