module InvestigationSearchkick
  extend ActiveSupport::Concern

  included do
    searchkick word_middle: %i[title product.name], callbacks: :async

    def search_data
      InvestigationSerializer.new(self).to_h
    end

    def should_index?
      deleted_at.nil?
    end
  end
end
