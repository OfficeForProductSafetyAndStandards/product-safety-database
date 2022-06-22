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
      object.created_at
    end

    def date_added
      object.created_at
    end

    def show_path
      object
    end
  end
end
