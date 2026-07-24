module AuthHelpers
  # Sign in as a role. Judgements attribute to the user's Referent, never to
  # the User — authorisation and provenance stay separate.
  def sign_in(role: "reviewer", name: "Jeff")
    user = User.register!(username: name.downcase, password: "correct horse",
                          role: role, name: name)
    post session_path, params: { username: user.username, password: "correct horse" }
    user
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
