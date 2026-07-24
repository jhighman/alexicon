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
