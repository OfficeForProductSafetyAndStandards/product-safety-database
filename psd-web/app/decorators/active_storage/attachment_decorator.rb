module ActiveStorage
  class AttachmentDecorator < ApplicationDecorator
    delegate_all

    def description
      h.simple_format(object.description)
    end

    def title
      object.metadata[:title] || object.filename
    end

    def date_of_activity
      Time.zone.parse(object.metadata["updated"]).to_s(:govuk)
    end

    def date_added
      object.blob.created_at.to_s(:govuk)
    end
  end
end
