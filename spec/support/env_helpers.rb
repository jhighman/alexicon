# Sets environment variables for the duration of a block and restores whatever
# was there before, including "not set at all", which is distinct from "empty".
module EnvHelpers
  def with_env(vars)
    previous = vars.keys.to_h { |k| [ k.to_s, ENV.fetch(k.to_s, :unset) ] }

    vars.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
    yield
  ensure
    previous.each { |k, v| v == :unset ? ENV.delete(k) : ENV[k] = v }
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
