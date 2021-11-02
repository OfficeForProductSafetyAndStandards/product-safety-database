module RedactedExport
  extend ActiveSupport::Concern

  class_methods do
    def redacted_export_attributes
      @redacted_export_attributes ||= []
    end

  protected

    def redacted_export_with(*attributes)
      RedactedExport.register_model_attributes self, *attributes
    end
  end

  def self.registry
    @registry ||= {}
  end

  def self.register_model_attributes(model, *attributes)
    registry[model] ||= []
    registry[model].concat attributes
    registry[model].uniq!
  end
end
