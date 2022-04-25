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
  validate :file_size_acceptable, if: -> { existing_document_file_id.blank? && document.present? }
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

      Rails.logger.info("Runninganalyzenow")
      # ok the below actually does run the analyzer
      # can we run it synchronously?
      document.analyze


      Rails.logger.info("Abouttosleep")
      sleep 10
      Rails.logger.info("Hasthisworked? metadata below")
      Rails.logger.info(document.metadata)
      Rails.logger.info(document)
      # yes
      # {"title"=>"fdsfsafsa", "description"=>"fdsadfsafasfdasfsad", "created_by"=>"195e256b-eb7b-45d7-9137-ac6f3b492b0c", "updated"=>"2022-04-24T14:59:04.786+01:00", "width"=>3024, "height"=>4032, "safe"=>true, "analyzed"=>true
      document.metadata["safe"] = false
      document.save

      self.existing_document_file_id = document.signed_id
    end
  end

private

  def file_size_acceptable
    return unless document.byte_size > max_file_byte_size

    errors.add(:base, :file_too_large, message: "File is too big, allowed size is #{max_file_byte_size / 1.megabyte} MB")
  end

  def max_file_byte_size
    100.megabytes
  end

  def file_is_free_of_viruses
    Rails.logger.info("RUNNINGFILESIZEISACCEPTABLEVALIDATION")
    return if document.metadata["safe"] == true

    errors.add(:base, :virus, message: "File has a virus")
  end
end
