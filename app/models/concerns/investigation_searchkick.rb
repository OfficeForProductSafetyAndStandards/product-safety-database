module InvestigationSearchkick
  extend ActiveSupport::Concern

  included do
    searchkick word_middle: %i[title product.name], callbacks: :async

    def search_data
      InvestigationSerializer.new(self).to_h
    end

    def should_index?
      submitted? && deleted_at.nil?
    end

    def self.scroll_results(skip)
      scroll_batch_size = 1000
      scroll_batches = skip / scroll_batch_size

      scroll_batches.times { scroll }

      remaining_skip = skip % scroll_batch_size
      batch = scroll
      results = batch.drop(remaining_skip).take(20)

      clear_scroll

      results
    end
  end
end
