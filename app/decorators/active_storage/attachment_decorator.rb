module ActiveStorage
  class AttachmentDecorator < ApplicationDecorator
    delegate_all

    def description
      h.simple_format(object.description)
    end

    def title
      object.metadata[:title] || object.filename.to_s
    end
  end
end
