module ActiveStorage
  class AttachmentDecorator < ApplicationDecorator
    delegate_all

    def title
      object.metadata[:title] || object.filename.to_s
    end
  end
end
