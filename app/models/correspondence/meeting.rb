# Recording of meeting correspondence is deprecated - existing data is still supported
class Correspondence::Meeting < Correspondence
  has_one_attached :transcript
  has_one_attached :related_attachment
end
