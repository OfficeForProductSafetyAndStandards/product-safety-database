namespace :data do
  desc "display stats on zip file"
  task zip_file_report: :environment do
    require "tty-table"
    include ActionView::Helpers::NumberHelper

    computed_stats = lambda { |entries|
      average_size = entries.map { |e| e[:size] }.instance_eval { reduce(:+) / size.to_f }
      unique_extensions = Set.new(entries.map { |e| File.extname(e[:name]) }).sort
      [number_to_human_size(average_size, precision: 2), unique_extensions.in_groups(5, false).reject(&:empty?).map { |line| line.reject(&:empty?).join(", ") }.join("\n")]
    }

    stats = []
    ActiveStorage::Blob.where(content_type: "application/zip").find_each do |blob|
      files = Hash.new([])
      Zip::InputStream.open(StringIO.new(blob.download)) do |input_stream|
        while (entry = input_stream.get_next_entry)
          files[blob.id] << { name: entry.name, size: entry.size } if entry.ftype == :file
        end
      end
      stats << computed_stats[files[blob.id]].unshift(blob.filename).unshift(blob.id)
    end
    table = TTY::Table.new(["Blob ID", "File name", "Average file size", "File extensions"], stats)

    print table.render(:unicode, multiline: true, alignments: %i[center center center right], padding: [2, 1])
    puts ""
  end
end
