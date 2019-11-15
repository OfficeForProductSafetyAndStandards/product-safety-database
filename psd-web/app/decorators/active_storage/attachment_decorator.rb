module ActiveStorage
  class AttachmentDecorator < ApplicationDecorator
    decorates_association :blob
    delegate_all

    def description
      h.simple_format(object.metadata[:description])
    end
  end
end
