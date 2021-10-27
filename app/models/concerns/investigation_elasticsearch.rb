module InvestigationElasticsearch
  extend ActiveSupport::Concern

  included do
    include Searchable

    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    settings do
      mappings do
        indexes :status, type: :keyword
        indexes :type, type: :keyword
        indexes :owner_id, type: :keyword
        indexes :creator_id, type: :keyword
        indexes :teams_with_access, type: :nested do
          indexes :id, type: :keyword
        end
      end
    end

    def as_indexed_json(*)
      as_json(
        only: %i[description
                 hazard_type
                 product_category
                 is_closed
                 type
                 updated_at
                 created_at
                 pretty_id
                 hazard_description
                 non_compliant_reason
                 coronavirus_related
                 risk_level],
        methods: %i[title creator_id owner_id tiebreaker_id],
        include: {
          teams_with_access: { only: %i[id name] },
          documents: {
            only: [],
            methods: %i[title description filename]
          },
          correspondences: {
            only: %i[correspondent_name details email_address email_subject overview phone_number email_subject]
          },
          activities: {
            methods: :search_index,
            only: []
          },
          businesses: {
            only: %i[legal_name trading_name company_number]
          },
          products: {
            only: %i[category description brand name product_code subcategory batch_number barcode]
          },
          complainant: {
            only: %i[name phone_number email_address other_details]
          },
          tests: {
            only: %i[details result legislation]
          },
          corrective_actions: {
            methods: :action_label,
            only: %i[details other_action legislation]
          },
          alerts: {
            only: %i[description summary]
          }
        }
      )
    end

    def self.highlighted_fields
      %w[*.* pretty_id title description hazard_type product_category hazard_description non_compliant_reason]
    end

    def self.fuzzy_fields
      %w[documents.*
         correspondences.*
         activities.*
         businesses.*
         products.*
         corrective_actions.*
         tests.*
         alerts.*
         title
         description
         hazard_type
         product_category
         hazard_description
         non_compliant_reason]
    end

    def self.exact_fields
      %w[pretty_id]
    end
  end
end
