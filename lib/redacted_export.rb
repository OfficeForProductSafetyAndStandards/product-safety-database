module RedactedExport
  extend ActiveSupport::Concern

  class_methods do
    def redacted_export_attributes
      @redacted_export_attributes ||= []
    end

  protected

    def redacted_export_with(*attributes)
      redacted_export_attributes.concat attributes
      redacted_export_attributes.uniq!
    end
  end

  def self.models
    ActiveRecord::Base.descendants.select do |model|
      !model.abstract_class? &&
        model.respond_to?(:redacted_export_attributes) &&
        model.redacted_export_attributes&.try(:any?)
    end
  end
end
