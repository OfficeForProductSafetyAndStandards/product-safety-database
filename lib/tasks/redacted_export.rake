namespace :redacted_export do
  desc "Emit SQL which will generate the redacted export tables"
  task generate_sql: %i[environment] do
    puts <<~SQL_OUTPUT
      --
      -- Redacted export generation SQL
      -- #{Time.zone.now}
      --

      DROP SCHEMA IF EXISTS redacted CASCADE; CREATE SCHEMA redacted;

    SQL_OUTPUT

    Rails.application.eager_load!
    RedactedExport.models.each do |model|
      attributes = model.redacted_export_attributes.join ", "

      puts <<~SQL_OUTPUT
        --
        -- #{model.name}
        --
        CREATE TABLE redacted.#{model.table_name} AS (SELECT #{attributes} FROM public.#{model.table_name});

      SQL_OUTPUT
    end

    puts <<~SQL_OUTPUT
      --
      -- Redacted export generation SQL complete
      --
    SQL_OUTPUT
  end
end
