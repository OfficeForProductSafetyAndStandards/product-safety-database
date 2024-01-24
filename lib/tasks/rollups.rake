namespace :rollups do
  desc "Generate rollups for daily/weekly/monthly PSD aggregate stats"
  task generate: :environment do
    GenerateRollupsJob.perform_now
  end
end
