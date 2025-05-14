module Antivirusable
  extend ActiveSupport::Concern

  def safe?
    return unless metadata&.key?("safe")

    metadata&.dig("safe") == true
  end

  def virus?
    return unless metadata&.key?("safe")

    metadata&.dig("safe") == false
  end

  def virus_scanned?
    metadata&.key?("analyzed") && metadata.key?("safe")
  end
end
