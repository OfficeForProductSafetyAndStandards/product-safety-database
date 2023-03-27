namespace :teams do
  desc "add trading standards regions"
  task :add_ts_region_information, [:filepath] => :environment do |_t, args|
    spreadsheet = Roo::Spreadsheet.open(args[:filepath])

    regions = spreadsheet.sheet("TS Region List").parse(headers: true)[1..]

    regions.each do |region|
      region_information = { name: region["Name"], acronym: region["Acronym"] }

      ts_region = TsRegion.find_or_initialize_by(region_information)

      ts_region.save!
    end

    teams = spreadsheet.sheet("Team data").parse(headers: true)[1..]

    teams.each do |team_data|
      next if team_data["Name of Region"].blank?

      ts_region = TsRegion.find_by_name(team_data["Name of Region"])

      team = Team.find_by_name(team_data["Team name"])

      team.update!(ts_region:) if team.present?
    end
  end

  desc "add regulator information to teams"
  task :add_regulator_information_to_teams, [:filepath] => :environment do |_t, args|
    spreadsheet = Roo::Spreadsheet.open(args[:filepath])

    teams = spreadsheet.sheet("Team data").parse(headers: true)[1..]

    regulators = teams.map { |t| t["Name of regulator (if Y)"] }.uniq.compact

    regulators.each do |regulator_name|
      regulator = Regulator.find_or_initialize_by(name: regulator_name)

      regulator.save!
    end

    teams.each do |team_data|
      team = Team.find_by_name(team_data["Team name"])

      next if team.blank?

      team.update!(regulator_information(team_data))
    end
  end
end

def regulator_information(team_data)
  return { local_authority: true } if team_data["External - LA"].casecmp("y").zero?

  return { internal_opss: true } if team_data["Internal"].casecmp("y").zero?

  regulator = Regulator.find_by_name(team_data["Name of regulator (if Y)"])

  { external_regulator: true, regulator: } if team_data["External Regulator"].casecmp("y").zero?
end
