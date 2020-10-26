# Recording of meeting correspondence is deprecated - existing data is still supported
class Correspondence::Meeting < Correspondence
  include DateConcern
  has_one_attached :transcript
  has_one_attached :related_attachment

  date_attribute :correspondence_date
end
