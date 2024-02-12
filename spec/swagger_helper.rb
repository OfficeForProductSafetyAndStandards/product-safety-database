# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.0",
      info: {
        title: "PSD API",
        version: "v1"
      },
      components: {
        schemas: {
          notification_object: {
            title: "Notification",
            type: :object,
            properties: {
              id: { type: :string },
              state: { type: :string, nullable: true },
              product_category: { type: :string, nullable: true },
              description: { type: :string, nullable: true },
              user_title: { type: :string },
              risk_level: { type: :string, nullable: true },
              reported_reason: { type: :string, nullable: true },
              non_compliant_reason: { type: :string, nullable: true },
              hazard_type: { type: :string, nullable: true },
              hazard_description: { type: :string, nullable: true },
              notifying_country: { type: :string },
              overseas_regulator_country: { type: :string, nullable: true },
              is_from_overseas_regulator: { type: :boolean },
              is_closed: { type: :boolean },
              created_at: { type: :string },
              updated_at: { type: :string }
            },
            required: %w[id]
          },
          product_object: {
            title: "Product",
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              brand: { type: :string },
              product_code: { type: :string, nullable: true },
              barcode: { type: :string, nullable: true },
              category: { type: :string },
              subcategory: { type: :string, nullable: true },
              description: { type: :string },
              country_of_origin: { type: :string },
              webpage: { type: :string, nullable: true },
              owning_team: { type: :object,
                             properties: {
                               name: { type: :string, nullable: true },
                               email: { type: :string, nullable: true },
                             } },
              product_images: { type: :array, items: { type: :object, properties: { url: { type: :string } } } },
            },
            required: %w[name]
          }
        }
      },
      paths: {}
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
