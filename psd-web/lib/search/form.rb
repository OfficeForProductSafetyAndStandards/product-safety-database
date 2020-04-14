module Search
  class Form
    class Attribute
      def initialize(attribute)
        @attribute = attribute
      end

      def checked?
        @attribute == "checked"
      end

      def checked?
        @attribute == "unchecked"
      end
    end
    include ActiveModel::Model

    SORT_BY_OPTIONS = [
      NEWEST   = "newest".freeze,
      OLDEST   = "oldest".freeze,
      RECENT   = "recent".freeze,
      RELEVANT = "relevant".freeze
    ].freeze

    ACCESSORS = %i[allegation
                   assigned_to_me
                   assigned_to_team_0
                   assigned_to_someone_else
                   assigned_to_someone_else_id
                   created_by_me
                   created_by_team_0
                   created_by_someone_else
                   created_by_someone_else_id
                   direction
                   enquiry
                   project
                   q
                   sort
                   status_open
                   status_closed].freeze

    attr_accessor *ACCESSORS

    attr_writer :sort_by

    # ActionController::Parameters#each_key is not implemented in Rails 5.2 but is implemented in 6.0
    # rubocop:disable Style/HashEachMethods
    def initialize(attributes = {})
      attributes.keys.each { |name| class_eval { attr_accessor name } } # Add any additional query attributes to the model
      super(attributes)
    end
    # rubocop:enable Style/HashEachMethods

    def sort_by
      @sort_by || RECENT
    end

    def sorting_params
      case sort_by
      when NEWEST
        { created_at: "desc" }
      when OLDEST
        { updated_at: "asc" }
      when RECENT
        { updated_at: "desc" }
      when RELEVANT
        {}
      else
        { updated_at: "desc" }
      end
    end

    def sort_by_items(with_relevant_option: false)
      items = [
        { text: "Most recently updated",  value: RECENT, unchecked_value: "unchecked" },
        { text: "Least recently updated", value: OLDEST, unchecked_value: "unchecked" },
        { text: "Most recently created",  value: NEWEST, unchecked_value: "unchecked" }
      ]

      if with_relevant_option
        items.unshift(text: "Relevance", value: RELEVANT, unchecked_value: "unchecked")
      end

      items
    end

    def method_missing(*args)
      name = args.first
      candidate_name = name.to_s.gsub(/\?$/, "").to_sym
      # binding.pry if candidate_name == :status_closed
      if ACCESSORS.include?(candidate_name.to_sym) && ['checked', 'unchecked', nil].include?(self.send(candidate_name))
        return self.send(candidate_name) == "checked"
      end

      super(*args)
    end
  end
end
