module ActiveStorage
  class AttachmentDecorator < ApplicationDecorator
    delegate_all

    def description
      h.simple_format(object.description)
    end
  end
end
