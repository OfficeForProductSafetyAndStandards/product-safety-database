namespace :data do
  desc "dumps users to csv"
  task export_users: [:environment] do

    require 'csv'
    file = "#{Rails.root}/public/user_data.csv"

    team_ids = %w[
      d29e259b-65ca-46b2-8d9d-6d1c02e98cec
      2d732b72-f3e6-4338-9a97-1630335f099b
      4cca5530-1a0a-443b-8fae-f5b1a04eff3d
      84ca0357-27e4-4478-9193-18d94ff160dd
      85fad78c-3adf-44d2-be40-a1bd61315310
      cc9dd730-0901-4657-b9cc-08850bf1613d
      14fe15a2-1283-43f7-b208-42573660596f
      1f6cf133-8f43-4d9a-862c-67eafa950a65
      f97c9842-5579-4eb5-8479-7344d92cc875
      4d213a88-e239-4cca-9a7b-f9436c07591f
      14bed221-bc5b-44e1-a96b-8e861f634d29
      ee1175d5-bd60-46e8-b03b-87d4ae110279
      7d30eff3-1b9f-42a0-b84e-d03be5ba14b2
      d4994cba-afac-400a-8d37-65b7f74922a2
      ad05fea6-1697-4664-97f5-9837563ce3ff
      70fe0523-4f0c-402e-a876-d88f10ac5191
      033a877c-6512-45d3-aa7e-9a47a95af9b1
      18a38047-9ccd-4720-89b6-281c06be29d5
      994e4e25-9a08-4856-8ac3-338757e4d5e2
      08039f63-bfe3-47b5-a1c0-b06947827f4c
      93e2e151-6c73-49e9-9db3-c49aac515437
      e7683f88-02eb-490e-abe9-62f8f2077fcf
      1a34afdb-bc36-49d4-826c-0db4fb134894
      bb988bef-f347-43e9-ba3b-bc6d96181d9e
      ffbfcb46-7da3-475b-8099-3f4cb526deff
    ]

    users = User.where(team_id: team_ids).order(:id)

    headers = ["Name", "Email", "Team Name", "Roles"]


    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      users.each do |user|
        writer << [user.name, user.email, user.team.name, user.roles.map(&:name).join(", ")]
      end
    end


  end
end
