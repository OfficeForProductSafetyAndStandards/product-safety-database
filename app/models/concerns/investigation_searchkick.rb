module InvestigationSearchkick
  extend ActiveSupport::Concern

  included do
    searchkick word_middle: %i[title product.name], callbacks: :async,
               mappings: { properties: { updated_at: { type: "date" }, created_at: { type: "date" } } },
               settings: { analysis: { analyzer: {
                                         searchkick_search: {
                                           type: "custom",
                                           tokenizer: "standard",
                                           filter: %w[lowercase searchkick_stemmer]
                                         },
                                         searchkick_search2: {
                                           type: "custom",
                                           tokenizer: "standard",
                                           filter: %w[lowercase searchkick_stemmer]
                                         },
                                         searchkick_index: {
                                           type: "custom",
                                           tokenizer: "standard",
                                           filter: %w[lowercase searchkick_stemmer]
                                         }
                                       },
                                       filter: {
                                         searchkick_stemmer: {
                                           type: "stemmer",
                                           language: "english"
                                         }
                                       } } }

    def search_data
      # Merge timestamp data with your existing serialized data
      InvestigationSerializer.new(self).to_h.merge(
        updated_at:,
        created_at:
      )
    end

    def should_index?
      result = submitted? && deleted_at.nil?
      Rails.logger.debug "Investigation #{id} should_index?: #{result} (submitted?: #{submitted?}, deleted_at: #{deleted_at})"
      result
    end
  end
end
