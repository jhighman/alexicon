# The framework is data, so most specs need it loaded. Seeds print a summary
# line; keep spec output readable.
module SeedHelpers
  def seed_quietly
    original, $stdout = $stdout, StringIO.new
    Rails.application.load_seed
  ensure
    $stdout = original
  end
end

RSpec.configure do |config|
  config.include SeedHelpers
end
