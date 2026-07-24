namespace :alexicon do
  desc "Create a user: rake 'alexicon:user[username,password,role]'"
  task :user, %i[username password role] => :environment do |_t, args|
    user = User.register!(username: args[:username], password: args[:password],
                          role: args[:role].presence || "viewer")
    puts "Created #{user.username} (#{user.role}) — acts as #{user.referent.passport}"
  end
end
