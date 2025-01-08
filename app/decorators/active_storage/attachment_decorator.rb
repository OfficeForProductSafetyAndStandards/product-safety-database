module ActiveStorage
  class AttachmentDecorator < ApplicationDecorator
    delegate_all

    def title
      object.metadata[:title] || object.filename.to_s
    end

    def supporting_information_title
      title
    end

    def event_type
      File.extname(object.filename.to_s)&.remove(".")&.upcase
    end

    def date_of_activity
      object.created_at.to_formatted_s(:govuk)
    end

    def date_added
      object.created_at.to_formatted_s(:govuk)
    end

    def description
      object.metadata[:description]
    end

    def updated_at
      Time.zone.parse(object.metadata[:updated]).to_formatted_s(:govuk)
    end

    def edit_path
      h.edit_investigation_document_path(Investigation.find_by(id: object.record_id), object)
    end

    def show_path
      h.investigation_document_path(Investigation.find_by(id: object.record_id), object)
    end
  end
end
