module Retireable
  extend ActiveSupport::Concern

  included do
    scope :retired, -> { where.not retired_at: nil }
    scope :not_retired, -> { where retired_at: nil }
  end

  def retired?
    retired_at.present?
  end

  def not_retired?
    !retired?
  end

  def mark_as_retired!
    return if retired?

    update! retired_at: Time.zone.now
  end
end
