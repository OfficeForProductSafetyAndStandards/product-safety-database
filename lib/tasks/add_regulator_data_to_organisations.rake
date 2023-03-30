namespace :organisations do
  desc "add trading standards regions"
  task :add_ts_region_information, [:filepath] => :environment do |_t, args|
    spreadsheet = Roo::Spreadsheet.open(args[:filepath])

    regions = spreadsheet.sheet("TS Region List").parse(headers: true)[1..]

    regions.each do |region|
      region_information = { name: region["Name"], acronym: region["Acronym"] }

      ts_region = TsRegion.find_or_initialize_by(region_information)

      ts_region.save!
    end

    organisations = spreadsheet.sheet("Team data").parse(headers: true)[1..]

    organisations.each do |organisation_data|
      next if organisation_data["Name of Region"].blank?

      ts_region = TsRegion.find_by_name(organisation_data["Name of Region"])

      organisation = Organisation.find_by_name(organisation_data["Team name"])

      organisation.update!(ts_region:) if organisation.present?
    end
  end

  desc "add regulator information to organisations"
  task :add_regulator_information_to_teams, [:filepath] => :environment do |_t, args|
    spreadsheet = Roo::Spreadsheet.open(args[:filepath])

    organisations = spreadsheet.sheet("Team data").parse(headers: true)[1..]

    regulators = organisations.map { |t| t["Name of regulator (if Y)"] }.uniq.compact

    regulators.each do |regulator_name|
      regulator = Regulator.find_or_initialize_by(name: regulator_name)

      regulator.save!
    end

    organisations.each do |organisation_data|
      organisation = Organisation.find_by_name(organisation_data["Team name"])

      next if organisation.blank?

      organisation.update!(regulator_information(organisation_data))
    end
  end
end

def regulator_information(organisation_data)
  return { local_authority: true } if organisation_data["External - LA"].casecmp("y").zero?

  return { internal_opss: true } if organisation_data["Internal"].casecmp("y").zero?

  regulator = Regulator.find_by_name(organisation_data["Name of regulator (if Y)"])

  { external_regulator: true, regulator: } if organisation_data["External Regulator"].casecmp("y").zero?
end
