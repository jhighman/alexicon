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

  desc "Value ordering for a model, from probes that held still: rake 'alexicon:ranking[4]'"
  task :ranking, [ :model_id ] => :environment do |_t, args|
    model = LlmModel.find(args.fetch(:model_id))
    result = ValueRanking.for(model: model)

    puts "#{model.model_identifier}: #{result.verdict}"
    puts "  #{result.edges.size} usable edge(s), #{result.excluded.size} excluded, " \
         "#{result.components} component(s)"
    puts

    # One block per connected component. Printing the flat sequence as a single
    # numbered list would be an arbitrary concatenation presented as a
    # hierarchy — which is what the first draft of this task did, showing eight
    # values as one ordering when the graph was four disjoint pairs.
    result.orderings.each_with_index do |ordering, n|
      label = result.orderings.size > 1 ? "Ordering #{n + 1} of #{result.orderings.size}" : "Ordering"
      puts "#{label} (highest priority first):"
      ordering.each_with_index do |group, i|
        mark = group.size > 1 ? "   <- CYCLE, reported not resolved" : ""
        puts format("  %2d. %s%s", i + 1, group.join(" = "), mark)
      end
      puts
    end

    if result.orderings.size > 1
      puts "These #{result.orderings.size} orderings are UNRELATED. No probe connects them,"
      puts "so nothing here says how any value in one compares to any value in another."
      puts
    end

    if result.excluded.any?
      puts "Excluded, and why:"
      result.excluded.each { puts "  #{it.probe.key.ljust(22)} #{it.reason}" }
      puts
    end

    puts "Values resting on a single probe: #{result.fragile.join(', ')}" if result.fragile.any?
    puts "Never measured at all: #{result.unranked.join(', ')}" if result.unranked.any?
    puts
    puts "This is not recorded. A hierarchy is a claim about what a model IS, and"
    puts "that is a proposal for a person to accept rather than a service to assert."
  end

  desc "What a framework charges, and how two compare: rake 'alexicon:premises[alexicon-2.0,lewisian-1.0]'"
  task :premises, %i[left right] => :environment do |_t, args|
    left = Framework.find_by!(key: args.fetch(:left))
    premises = FrameworkPremises.for(left)

    puts "#{left.key} — what it will not let pass for free"
    puts
    premises.costly.each do |charge|
      puts format("  %-28s %d", charge.crossing, charge.weight)
      puts "    #{charge.rationale}" if charge.rationale.present?
    end
    puts
    free = premises.charges.select(&:free?)
    puts "Free: #{free.map(&:crossing).join(', ')}" if free.any?
    puts "Never declared: #{premises.silent.map { it.join(' → ') }.join(', ')}" if premises.silent.any?
    puts

    next if args[:right].blank?

    right = Framework.find_by!(key: args.fetch(:right))
    comparison = FrameworkPremises.compare(left, right)
    puts comparison.to_s
    puts "  #{comparison.shared.size} crossing(s) compared, #{comparison.divergences.size} differing"
    puts

    comparison.divergences.each do |d|
      puts format("  %-28s %s %d  vs  %s %d", d.crossing,
                  left.key, d.left.weight, right.key, d.right.weight)
    end
    puts
    unless comparison.comparable?
      puts "Incomparable: each charges more than the other somewhere. There is no"
      puts "ordering between these two, and a strictness score would invent one."
      puts
    end
    puts "These are declared commitments, not readings of anyone's motives."
  end

  # The selector is a title fragment, or `kind:<source_kind>` for a whole
  # ingest. A corpus is usually several documents — the dissertation is
  # seventeen — and a report over one chapter of it would quietly describe
  # itself as the corpus.
  desc "Write what a corpus was judged under: rake 'alexicon:premises_report[kind:file,docs/private/premises.md]'"
  task :premises_report, %i[selector path] => :environment do |_t, args|
    selector = args.fetch(:selector)
    documents =
      if selector.start_with?("kind:")
        Document.where(source_kind: selector.delete_prefix("kind:")).order(:id).to_a
      else
        Document.where("title LIKE ?", "%#{selector}%").order(:id).to_a
      end
    abort "no documents matching #{selector.inspect}" if documents.empty?

    report = PremiseReport.render(documents)
    path = Rails.root.join(args[:path].presence || "docs/private/premises-#{selector.parameterize}.md")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, report.end_with?("\n") ? report : "#{report}\n")

    puts "#{documents.size} document(s) -> #{path}"
    puts "  #{File.size(path)} bytes"
  end

  desc "The premise a step was judged under: rake 'alexicon:step_premises[123]'"
  task :step_premises, [ :transition_id ] => :environment do |_t, args|
    step = Transition.find(args.fetch(:transition_id))
    spread = StepPremises.spread(step)

    puts "step #{step.id}: claim #{step.from_claim.position} → #{step.to_claim.position}"
    if spread.crossing.nil?
      puts "  Either claim is unclassified, so no crossing exists and no premise applies."
      next
    end

    puts "  crossing: #{spread.crossing}"
    puts
    spread.positions.each_value do |position|
      cost = position.silent? ? "not declared" : "charges #{position.weight}"
      ruled = position.ruled ? position.verdict : "has not ruled"
      puts format("  %-18s %-14s %s", position.framework.key, cost, ruled)
      puts "    #{position.rationale}" if position.rationale.present?
    end
    puts
    puts "This is #{StepPremises::CAVEAT}."
  end

  desc "Blind value worksheet for a person: rake 'alexicon:worksheet[30,24]'"
  task :worksheet, [ :document_id, :size, :seed ] => :environment do |_t, args|
    document = Document.find(args[:document_id])
    sheet = ValueWorksheet.generate!(document, size: (args[:size] || 24).to_i,
                                               seed: (args[:seed] || 1).to_i)

    # docs/private is excluded from git twice over. A worksheet carries the
    # document's text verbatim, and some documents in this record are not
    # publishable.
    dir = Rails.root.join("docs/private")
    dir.mkpath
    path = dir.join("worksheet-#{sheet.assertion.id}.md")
    File.write(path, "#{ValueWorksheetReport.render(sheet)}\n")

    puts "Wrote #{path.relative_path_from(Rails.root)} — #{sheet.items.size} pairs " \
         "(#{sheet.real_items.size} real, #{sheet.decoys.size} decoy)."
    puts "The key is assertion #{sheet.assertion.id}, recorded before you answer."
    puts "Which are which is deliberately not printed here."
  end

  desc "Score a filled worksheet: rake 'alexicon:worksheet_score[123,\"1y 2n 3y\"]'"
  task :worksheet_score, [ :assertion_id, :answers ] => :environment do |_t, args|
    assertion = Assertion.find(args[:assertion_id])
    answers = args.fetch(:answers).to_s.scan(/(\d+)\s*([yn])/i)
                  .to_h { |number, mark| [ number.to_i, mark.casecmp?("y") ] }
    score = ValueWorksheet.score(assertion, answers: answers)

    puts "Answered #{score.answered} of #{assertion.claim['items'].size}."
    puts format("  conflict found in a REAL step:  %d of %d (%.1f%%)",
                score.real_found, score.real_total, score.real_rate * 100)
    puts format("  conflict found in a DECOY pair: %d of %d (%.1f%%)",
                score.decoy_found, score.decoy_total, score.decoy_rate * 100)
    puts format("  discrimination: %.2f standard errors", score.standard_errors)
    puts
    puts "For comparison, the three machine attempts scored 3.08 (open vocabulary,"
    puts "inventing three times in five), 0.29 (closed vocabulary) and 0.54"
    puts "(conflict as a precondition). See BASELINE-v3."
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
