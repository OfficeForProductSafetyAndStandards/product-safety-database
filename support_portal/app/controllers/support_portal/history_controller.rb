module SupportPortal
  class HistoryController < ApplicationController
    def index
      changes = PaperTrail::Version
        .includes(:item)
        .joins("LEFT JOIN users ON users.id::text = versions.whodunnit")
        .where(item_type: %w[User Role])
        .select("versions.*, COALESCE(users.name, 'Unknown') AS whodunnit")
        .order(created_at: :desc)
      @records_count = changes.size
      @pagy, @records = pagy(changes)
    end
  end
end
