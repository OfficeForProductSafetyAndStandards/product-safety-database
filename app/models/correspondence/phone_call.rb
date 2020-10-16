class Correspondence::PhoneCall < Correspondence
  include DateConcern

  date_attribute :correspondence_date

  has_one_attached :transcript
end
