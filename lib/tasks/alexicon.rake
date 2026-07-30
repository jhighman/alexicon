namespace :alexicon do
  desc "Create a user: rake 'alexicon:user[username,password,role]'"
  task :user, %i[username password role] => :environment do |_t, args|
    user = User.register!(username: args[:username], password: args[:password],
                          role: args[:role].presence || "viewer")
    puts "Created #{user.username} (#{user.role}) — acts as #{user.referent.passport}"
  end
end

namespace :alexicon do
  desc "Classify and judge a document: rake 'alexicon:analyse[ID]'"
  task :analyse, [ :document_id ] => :environment do |_t, args|
    document = Document.find(args[:document_id])
    abort "Document is locked — answer the identity STOPs first." unless document.executable?

    puts "Classifying #{document.unclassified_claims.count} claims…"
    result = DocumentClassification.call(document)
    puts "  #{result.classified} classified, #{result.abstained} abstained, #{result.skipped} skipped"

    document.claims.each do |claim|
      c = claim.classification
      puts format("  %-52s %-13s %s", claim.text.truncate(50),
                  claim.category&.name || "—",
                  c&.confidence ? "#{(c.confidence * 100).round}%" : "")
      puts "      #{c.rationale}" if c&.rationale.present?
    end

    puts "\nJudging the steps…"
    GovernanceSentinel.review_document!(document)
    DomainSentinel.review_all!(document)

    document.transitions.each do |t|
      puts format("  %-13s -> %-13s %s", t.from_claim.category&.name, t.to_claim.category&.name, t.verdict)
    end

    puts "\nFlags:"
    document.flags.includes(:asserter).each { puts "  #{it.asserter.name}: #{it.message.truncate(90)}" }

    calls = LlmInvocation.where(assertion_id: document.claims.flat_map { it.assertions.ids })
    puts "\nCalls: #{calls.count} · #{calls.sum(:total_tokens)} tokens · " \
         "$#{calls.sum(:cost_usd).round(4)} · #{calls.average(:latency_ms)&.round} ms avg"
  end
end

namespace :alexicon do
  desc "Issue an API token for a person: rake 'alexicon:token[username,name]'"
  task :token, %i[username name] => :environment do |_t, args|
    user = User.find_by!(username: args[:username].to_s.downcase)
    token = ApiToken.issue!(referent: user.referent, name: args[:name].presence || "cli",
                            role: user.role, issued_by: user.referent)

    puts "#{token.name} — acts as #{user.referent.passport} (#{token.role})"
    puts token.plaintext
    puts "Shown once. It is stored as a digest and cannot be recovered."
  end

  # An agent is a referent like any other, and its judgements read as inference
  # because of what it is, not because of how it authenticated.
  desc "Create an agent and issue its token: rake 'alexicon:agent[key,name,role]'"
  task :agent, %i[key name role] => :environment do |_t, args|
    key = args[:key].presence or abort "Give the agent a key: rake 'alexicon:agent[review-agent,...]'"
    referent = Referent.find_or_create_by!(key: key) do |r|
      r.name = args[:name].presence || key.titleize
      r.subject = "System"
      r.role = "Agent"
      r.primitive = "system"
    end

    token = ApiToken.issue!(referent: referent, name: "#{key}-token",
                            role: args[:role].presence || "reviewer")

    puts "#{referent.passport}"
    puts token.plaintext
    puts
    puts "It may read. It may judge nothing until someone delegates an act:"
    puts "  Delegation.create!(agent_pattern: #{key.inspect}, act: \"dispose_flag\","
    puts "                     granted_by: <your referent>, rationale: \"...\")"
    puts "Acts: #{Delegation::ACTS.join(', ')}"
  end
end

namespace :alexicon do
  desc "Re-render docs/LEXICON.md from the framework's own vocabulary"
  task lexicon: :environment do
    path = Rails.root.join("docs/LEXICON.md")
    report = Lexicon.render
    File.write(path, report.end_with?("\n") ? report : "#{report}\n")

    lexicon = Lexicon.new
    puts "Wrote #{path.relative_path_from(Rails.root)} — #{lexicon.terms.size} terms, " \
         "#{lexicon.collisions.size} word(s) carried by more than one."
  end

  desc "Judge a document's steps under another framework: rake 'alexicon:premise[30,lewisian-1.0]'"
  task :premise, [ :document_id, :framework ] => :environment do |_t, args|
    document = Document.find(args[:document_id])
    rival = Framework.find_by!(key: args.fetch(:framework))
    current = Framework.current!

    puts "Judging document #{document.id} under #{rival.name} (#{rival.key})."
    puts "Nothing recorded under #{current.name} is touched: both sets of rulings stand.\n\n"

    # Only what this framework has not already ruled on. Re-reviewing would
    # record a second identical ruling, and a second ruling that happened to
    # differ — because the claims were re-read in between — would show up as the
    # sentinel drifting. Manufacturing drift by re-running is exactly the
    # confusion `unstable?` exists to report.
    document.require_executable!
    pending = document.transitions.select { it.verdict(framework: rival) == "undetermined" }
    puts "#{pending.size} of #{document.transitions.size} steps not yet ruled on by #{rival.key}.\n\n"
    pending.each { GovernanceSentinel.review!(it, framework: rival) }

    steps = document.transitions.to_a
    differ = steps.select { it.verdict(framework: rival) != it.verdict(framework: current) }

    puts "#{steps.size} steps · #{steps.size - differ.size} agree · #{differ.size} differ\n\n"
    differ.each do |t|
      puts format("  %-30s %s=%-11s %s=%s",
                  "#{t.from_claim.category&.key} → #{t.to_claim.category&.key}",
                  current.key, t.verdict(framework: current), rival.key, t.verdict(framework: rival))
    end
    puts "\nA difference is a fact about the premises, not about the text."
  end

  desc "Re-render docs/BASELINE.md from the recorded measurements: rake 'alexicon:baseline[v1]'"
  task :baseline, [ :version ] => :environment do |_t, args|
    version = args[:version].presence || "v1"
    report = BaselineReport.render(version: version)
    # The first baseline keeps the published filename other documents link to;
    # later ones sit beside it. They are not revisions of each other — a baseline
    # taken under different conditions is a different measurement, not a newer
    # reading of the same one.
    path = Rails.root.join(version == "v1" ? "docs/BASELINE.md" : "docs/BASELINE-#{version}.md")
    File.write(path, report.end_with?("\n") ? report : "#{report}\n")

    count = Baseline.for(version: version).size
    puts "Wrote #{path.relative_path_from(Rails.root)} — #{count} measurement(s) in #{version}."
  end
end
