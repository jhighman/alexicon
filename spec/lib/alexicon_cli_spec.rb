require "rails_helper"

# The command line is a standalone script that boots no Rails, so it is loaded
# rather than required. Its `exit` is guarded by `$PROGRAM_NAME == __FILE__`,
# which is false here.
#
# What is covered is everything that needs no server: how a token is resolved,
# what happens when there is none, and how a refusal is explained. The HTTP
# paths are exercised against the real API by the request specs for those
# endpoints — duplicating them here with stubs would test the stubs.
load Rails.root.join("bin/alexicon").to_s

RSpec.describe "the alexicon command line" do
  let(:cli) { Alexicon::CLI.new }

  around do |example|
    original = ENV.to_hash.slice("ALEXICON_URL", "ALEXICON_TOKEN")
    ENV.delete("ALEXICON_URL")
    ENV.delete("ALEXICON_TOKEN")
    example.run
    ENV.update(original)
  end

  def client_for(argv)
    args = argv.dup
    cli.send(:client, cli.send(:extract_options, args))
  end

  def config_of(client) = [ client.send(:base).to_s, client.send(:token) ]

  describe "finding a token" do
    it "takes one from the flags" do
      _, token = config_of(client_for(%w[--token=alx_flag --url=http://example.test type 1]))

      expect(token).to eq "alx_flag"
    end

    it "takes one from the environment" do
      ENV["ALEXICON_TOKEN"] = "alx_env"

      expect(config_of(client_for(%w[documents])).last).to eq "alx_env"
    end

    it "prefers the flag to the environment" do
      ENV["ALEXICON_TOKEN"] = "alx_env"

      expect(config_of(client_for(%w[--token=alx_flag documents])).last).to eq "alx_flag"
    end

    it "reads one from the config file" do
      file = Tempfile.new("alexicon")
      file.write("url=http://configured.test\ntoken=alx_file\n")
      file.close
      stub_const("Alexicon::CONFIG_FILE", file.path)

      url, token = config_of(client_for(%w[documents]))

      expect(token).to eq "alx_file"
      expect(url).to eq "http://configured.test"
    ensure
      file&.unlink
    end

    it "falls back to localhost when no url is given anywhere" do
      expect(config_of(client_for(%w[--token=alx_x documents])).first).to start_with "http://localhost:3000"
    end

    # The remedy is issuing one, so the error says how.
    it "explains how to get one rather than reporting a missing variable" do
      expect { client_for(%w[documents]) }.to raise_error(Alexicon::Error, /alexicon:token/)
    end
  end

  describe "flags" do
    it "removes them from the arguments, leaving the command and its id" do
      args = %w[--url=http://x.test type 27 --token=alx_y]
      cli.send(:extract_options, args)

      expect(args).to eq %w[type 27]
    end
  end

  describe "explaining a refusal" do
    let(:client) { Alexicon::Client.new(url: "http://x.test", token: "alx_z") }

    # The posture the system starts in, and the one a person will meet first.
    it "names the act and who must delegate it" do
      body = { "error" => "not_delegated", "detail" => "Agent may not type claim without a person.",
               "act" => "type_claim", "acting_as" => "review-agent" }

      message = client.send(:delegation_message, body)

      expect(message).to include "type_claim", "review-agent", "A person must delegate"
    end

    it "says what to do about an unauthenticated call" do
      response = instance_double(Net::HTTPUnauthorized, code: "401")

      expect(client.send(:failure_message, response, {})).to match(/ALEXICON_TOKEN/)
    end

    it "distinguishes a role refusal from a missing delegation" do
      response = instance_double(Net::HTTPForbidden, code: "403")

      expect(client.send(:failure_message, response, {})).to match(/role does not allow/)
    end
  end

  # Piped output is diffed and grepped; escape codes would break both.
  describe "styling" do
    it "emits no escape codes when nobody is watching" do
      allow($stdout).to receive(:tty?).and_return(false)

      expect(Alexicon::Style.bold("plain")).to eq "plain"
      expect(Alexicon::Style.red("plain")).to eq "plain"
    end
  end

  describe "usage" do
    it "leads with the command it exists for" do
      expect { cli.run([ "help" ]) }.to output(/type ID .*type a document's claims blind/).to_stdout
    end
  end
end
