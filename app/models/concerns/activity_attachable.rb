module ActivityAttachable
  extend ActiveSupport::Concern

  module ClassMethods
    attr_accessor :attachment_names

  private

    def with_attachments(names)
      @attachment_names = names
      @attachment_names.each_key do |key|
        class_eval do
          has_one_attached key
        end
      end
    end
  end

  def attachment_names
    klass = self.class
    while klass.respond_to? :attachment_names
      return klass.attachment_names if klass.attachment_names.present?

      klass = klass.superclass
    end
    {}
  end

  def has_attachment?
    return false if attachment_names.blank?

    attachment_names.any? { |key, _| send(key)&.attached? }
  end

  def attachments
    return {} unless has_attachment?

    attachment_names
        .map { |attachment_name, display_name| [display_name, send(attachment_name)] }
        .select { |_, attachment| attachment.attached? }
        .to_h
  end

  def attached_image?
    attachment_names.keys.any? { |name| send(name).image? }
  end

  def attach_blob(file_blob, attachment_key = attachment_names.keys.first)
    raise "You have not passed a blob to attach_blob in ActivityAttachable" unless file_blob.is_a? ActiveStorage::Blob
    return unless attachment_key.present? && file_blob.present?

    send(attachment_key).attach file_blob
  end
end
