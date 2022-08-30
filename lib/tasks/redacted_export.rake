namespace :redacted_export do
  desc "Emit SQL which will generate the redacted export tables"
  task generate_sql: %i[environment] do
    Rails.application.eager_load!
    puts RedactedExport.registry.to_sql
  end

  desc "Batch-copy appropriate S3 objects to the export bucket"
  task copy_s3_objects: %i[environment] do
    require "csv"

    source_bucket = Rails.configuration.redacted_export["source_bucket"]
    destination_arn = "arn:aws:s3:::#{Rails.configuration.redacted_export['destination_bucket']}"
    raise "Cannot determine buckets from configuration" if source_bucket.blank? || destination_arn.end_with?(":")

    our_job_id = Time.zone.now.iso8601
    manifest_key = "manifests/#{our_job_id}.csv"

    object_keys = RiskAssessment.with_attached_risk_assessment_file.pluck("active_storage_blobs.key") +
      Test::Result.with_attached_document.pluck("active_storage_blobs.key")

    manifest_csv = CSV.generate do |csv|
      object_keys.each do |key|
        csv << [source_bucket, key]
      end
    end

    s3_client = Aws::S3::Client.new(
      region: Rails.configuration.redacted_export["region"],
      access_key_id: Rails.configuration.redacted_export["access_key_id"],
      secret_access_key: Rails.configuration.redacted_export["secret_access_key"]
    )
    response = s3_client.put_object(
      bucket: Rails.configuration.redacted_export["destination_bucket"],
      key: manifest_key,
      content_type: "text/csv",
      body: manifest_csv
    )
    manifest_etag = response.etag

    s3control_client = Aws::S3Control::Client.new(
      region: Rails.configuration.redacted_export["region"],
      access_key_id: Rails.configuration.redacted_export["access_key_id"],
      secret_access_key: Rails.configuration.redacted_export["secret_access_key"]
    )

    response = s3control_client.create_job({
      account_id: Rails.configuration.redacted_export["account_id"].to_s,
      confirmation_required: false,
      operation: {
        s3_put_object_copy: {
          target_resource: destination_arn,
          target_key_prefix: "files"
        }
      },
      report: {
        bucket: destination_arn,
        format: "Report_CSV_20180820",
        enabled: true,
        prefix: "reports",
        report_scope: "AllTasks"
      },
      client_request_token: our_job_id,
      manifest: {
        spec: {
          format: "S3BatchOperations_CSV_20180820",
          fields: %w[Bucket Key]
        },
        location: {
          object_arn: "#{destination_arn}/#{manifest_key}",
          etag: manifest_etag
        },
      },
      description: "Redacted Export #{our_job_id}",
      priority: 100,
      role_arn: Rails.configuration.redacted_export["role_arn"]
    })

    puts "Created job: #{response.job_id}"
  end
end
