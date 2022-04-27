class DocumentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty
  include SanitizationHelper

  attribute :title
  attribute :description
  attribute :existing_document_file_id
  attribute :document

  validates :title, presence: true
  validates :document, presence: true, if: -> { existing_document_file_id.blank? }
  validates :description, length: { maximum: 10_000 }
  validate :file_size_acceptable, if: -> { document.present? }
  validate :file_is_free_of_viruses, if: -> { document.present? }

  before_validation do
    trim_line_endings(:description)
  end

  def self.from(file)
    new(existing_document_file_id: file.signed_id, title: file.metadata[:title], description: file.metadata[:description])
  end

  def initialize(*args)
    super
    self.document ||= ActiveStorage::Blob.find_signed!(existing_document_file_id) if existing_document_file_id.present?
  end

  def cache_file!(user)
    if document.is_a?(ActiveStorage::Blob)
      document.metadata["title"] = title
      document.metadata["description"] = description
      document.metadata["updated"] = Time.zone.now
      document.save!
    elsif document
      self.document = ActiveStorage::Blob.create_and_upload!(
        io: document,
        filename: document.original_filename,
        content_type: document.content_type
      )
      document.update!(metadata: { title:, description:, created_by: user.id, updated: Time.zone.now })

      # i think we need to run analyze synchronously because we want the AntiVirusAnalyzer to run now so that we can know if the document is safe before we attach it
      Rails.logger.info "£££££££ Does it create a background job if we call analyze directly?"
      document.analyze_later

      self.existing_document_file_id = document.signed_id
    end
  end

private

  def file_size_acceptable
    return unless document.byte_size > max_file_byte_size

    errors.add(:base, :file_too_large, message: "Files must be smaller than #{max_file_byte_size / 1.megabyte} MB in size")
  end

  def max_file_byte_size
    100.megabytes
  end

  def file_is_free_of_viruses
    # don't run this validation unless document has been analyzed by antivirus analyzer
    return unless document.metadata.keys.include?("safe")
    return if document.metadata["safe"] == true

    errors.add(:base, :virus, message: "Files must be virus free")
  end
end
