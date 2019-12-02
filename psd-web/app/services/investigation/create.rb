class Investigation < ApplicationRecord
  class Create

    def initialize(attributes, attachment: nil)
      self.attributes = attributes
      self.attachment = attachment
    end

    def call
      investigation.documents.attach(attachment) if attachment
      investigation.save
      investigation
    end

    private
    attr_accessor :attributes, :attachment

    def investigation
      @investigation ||= Investigation.new(attributes)
    end
  end
end
