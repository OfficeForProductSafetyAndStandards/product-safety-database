namespace :data do
  desc "display stats on zip file"
  task zip_file_report: [:environment] do
    Rails.logger = ActiveSupport::Logger.new(STDOUT)
    require "tty-table"
    require "active_storage/filename"
    include ActionView::Helpers::NumberHelper

    extension_list_line_breakpoint = 10

    computed_stats = lambda { |entries|
      average_size = entries.map { |e| e[:size] }.instance_eval { reduce(:+) / size.to_f }
      extensions = entries.map { |e| File.extname(e[:name]) }.reject(&:empty?).sort
      [number_to_human_size(average_size, precision: 2), extensions]
    }

    compute_associated_record = lambda do |blob|
      stats = []

      if (investigation_attachment = blob.attachments.detect { |attachment| attachment.record.is_a?(Investigation) })
        investigation = investigation_attachment.record
      end

      if investigation
        stats << "case: #{investigation.pretty_id}"
      else
        associated_to_investigation_record_attachment ||= blob.attachments.detect { |attachment| attachment.respond_to?(:investigation_id) || attachment }

        if associated_to_investigation_record_attachment && associated_to_investigation_record_attachment.record.respond_to?(:investigation)
          stats << "case: #{associated_to_investigation_record_attachment.record.investigation.pretty_id}"
        elsif associated_to_investigation_record_attachment && associated_to_investigation_record_attachment.record.respond_to?(:investigations)
          stats << associated_to_investigation_record_attachment.record.investigations.map do |i|
            "case: #{i.pretty_id}"
          end
        end
      end

      blob.attachments.map do |attachment|
        stats << [attachment.record_type, attachment.record_id].join(" - ")
      end

      stats.join("\n")
    end

    zip_file_count         = ActiveStorage::Blob.where(content_type: "application/zip").count
    statistics             = []
    queue                  = Queue.new

    Rails.logger.info "Downloading: #{zip_file_count}"
    threads = []
    ActiveStorage::Blob.where(content_type: "application/zip").find_each do |blob|
      threads << Thread.new do
        Rails.logger.info "Downloading #{blob.filename} with id: #{blob.id}"
        queue << [blob, blob.download]
        Rails.logger.info "Downloaded #{blob.filename} with id: #{blob.id}"
      end
    end

    thread = Thread.new do
      while (blob, zip_file = queue.pop)
        Rails.logger.info "Scanning file for #{blob.filename} with id: #{blob.id} - queue size: #{queue.size}"
        files = Hash.new([])
        begin
          Zip::InputStream.open(StringIO.new(zip_file)) do |input_stream|
            while (entry = input_stream.get_next_entry)
              files[blob.id] << { name: File.basename(entry.name), size: entry.size } unless entry.name_is_directory?
            end
          end
        rescue Zip::GPFBit3Error =>
          Rails.logger.warn "Skipping #{blob.filename}: malformed zip"
        end
        statistics << computed_stats[files[blob.id]]
                        .unshift(blob.filename)
                        .unshift(blob.id)
                        .unshift(compute_associated_record[blob])
        Rails.logger.info "Scanned file for #{blob.filename} with id: #{blob.id}"

        queue.close if threads.none?(&:alive?)
      end
    end

    thread.join

    process_unique_file_extensions = lambda { |stats|
      stats.deep_dup.map do |stat|
        extensions = stat[4].uniq
        stat[4] = if extensions.size > extension_list_line_breakpoint
                    extensions.in_groups(extensions.size / extension_list_line_breakpoint, false).reject(&:empty?).map { |line| line.reject(&:empty?).join(", ") }.join("\n")
                  else
                    extensions.reject(&:empty?).join(", ")
                  end
        stat
      end
    }

    extensions_count = statistics.flat_map(&:last).group_by(&:itself).each_with_object({}) { |(extension, extensions), hash| hash[extension] = extensions.size }
    total_file = extensions_count.values.reduce(:+)

    table = TTY::Table.new(["Blob ID", "File name", "Associated records", "Average file size", "File extensions"], process_unique_file_extensions[statistics])
    print table.render(:unicode, multiline: true, alignments: %i[center center center center left], padding: [2, 1])
    puts ""

    extensions_count = extensions_count.sort_by { |_extension, value| value }.reverse

    table = TTY::Table.new(%w[Extension count percentage], extensions_count.map { |k, v| [k, v, number_to_percentage((v / total_file.to_f) * 100)] })
    print table.render(:unicode, multiline: true, alignments: %i[center center center], padding: [2, 1])
    puts ""

    print "\n#{zip_file_count} zip files analysed.\n"
  end
end
