require "rails_helper"

# The presentation layer is where guards get lost. `StepValueJudge` makes the
# subject of a value reading structurally a Transition so that "this author
# values X" cannot be written; a report that attributed the same readings to a
# person would undo that here, where nobody would be looking.
RSpec.describe ProfileReport do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…", title: "A text") }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }
  let(:sentinel) { Referent.find_by!(key: "governance-sentinel") }
  let(:judge) { Referent.find_by!(key: StepValueJudge::JUDGE) }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  # Collapses wrapping and blockquote markers, so a spec tests the sentence
  # rather than the column the heredoc happened to break at.
  def flat(text) = text.gsub(/^>\s?/, "").gsub(/\s+/, " ")

  def claim(text, kind = nil, readings: 3)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    readings.times { c.classify!(category(kind), asserter: classifier, confidence: 0.9) } if kind
    c
  end

  def unearned_step(from_kind = "interpretive", to_kind = "ontological")
    t = Transition.create!(source: claim("From.", from_kind), target: claim("To.", to_kind))
    t.record_verdict!("unearned", asserter: sentinel)
    t
  end

  def value_reading(transition, protects: "the generalisability of an insight")
    Assertion.create!(asserter: judge, subject: transition, act: "assert",
                      claim: { "inference" => "step value", "move" => "interpretive -> ontological",
                               "protects" => protects, "subordinates" => "the single case",
                               "confidence" => 0.9, "rationale" => "the scope widens" })
  end

  describe "who the report is about" do
    it "names the document as its subject, and says so" do
      claim("A claim.", "observation")

      report = described_class.render(document)

      expect(flat(report)).to include "This describes a **document**"
      expect(flat(report)).to include "It is not about its author"
    end

    # The guard the whole design turns on, checked at the layer where it would
    # otherwise be lost.
    it "attributes a value reading to the step, never to a person" do
      value_reading(unearned_step)

      report = described_class.render(document)

      expect(flat(report)).to include "a claim about **that step**"
      expect(report).not_to match(/the (subject|author|writer) (demonstrates|values|shows|exhibits)/i)
      expect(report).not_to match(/\bidentity formation\b|\btrust in sincerity\b/i)
    end
  end

  describe "sections" do
    it "reports what kinds of claim the document makes" do
      2.times { claim("Observed.", "observation") }
      claim("Concluded.", "ontological")

      report = described_class.render(document)

      expect(report).to match(/\| Observation \| 2 \| 66\.7% \|/)
      expect(report).to match(/\| Ontological \| 1 \| 33\.3% \|/)
    end

    it "reports unearned steps by the kind of move" do
      unearned_step("observation", "normative")

      expect(described_class.render(document)).to include "| observation → normative | 1 |"
    end

    # A section with nothing behind it is absent rather than empty.
    it "omits a section that has no evidence" do
      claim("A claim.", "observation")

      report = described_class.render(document)

      expect(report).not_to include "What the unearned steps put first"
    end

    it "always carries the limits, because they do not depend on evidence" do
      claim("A claim.", "observation")

      expect(described_class.render(document)).to include "What this report cannot tell you"
    end
  end

  # The value layer's false-positive rate is measured, and a report that used it
  # without saying so would be a score of unknown provenance.
  describe "the weakest section" do
    it "states the false-positive rate beside the readings it draws on" do
      value_reading(unearned_step)

      report = described_class.render(document)

      expect(flat(report)).to include "three attempts to make it have failed"
      expect(flat(report)).to include "the one that invented most"
      expect(flat(report)).to include "never as a finding"
    end

    it "counts how many steps it actually read, against how many were flagged" do
      first = unearned_step
      unearned_step
      value_reading(first)

      expect(described_class.render(document)).to match(/Read at 1 of the 2 unearned steps/)
    end
  end

  # A disposal is recorded beside a judgement rather than over it, so a rejected
  # reading is still standing and nothing but this filters it out. Rendering one
  # would be the report contradicting the record it is generated from.
  describe "what a reviewer decided" do
    let(:reviewer) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

    def dispose(assertion, verdict)
      Assertion.create!(asserter: reviewer, subject: assertion, act: verdict, claim: {})
    end

    it "does not show a reading a reviewer rejected" do
      kept = value_reading(unearned_step, protects: "the kept one")
      dispose(value_reading(unearned_step, protects: "the rejected one"), "reject")

      report = described_class.render(document)

      expect(report).to include "the kept one"
      expect(report).not_to include "the rejected one"
      expect(kept.reload.disposition).to eq "open"
    end

    it "still counts a rejected reading among those taken, and says it is not shown" do
      value_reading(unearned_step)
      dispose(value_reading(unearned_step), "reject")

      report = flat(described_class.render(document))

      expect(report).to match(/Read at 2 of the 2 unearned steps/)
      expect(report).to include "1 was rejected by a reviewer and is not shown"
    end

    it "marks a reading a reviewer let stand differently from one nobody has read" do
      dispose(value_reading(unearned_step, protects: "the reviewed one"), "accept")
      value_reading(unearned_step, protects: "the untouched one")

      report = described_class.render(document)

      expect(report).to match(/the reviewed one.*\*\*let stand\*\*/)
      expect(report).to match(/the untouched one.*unreviewed/)
      expect(flat(report)).to include "1 was reviewed and let stand and 1 has not been looked at"
    end

    it "puts what a person confirmed above what nobody has looked at" do
      value_reading(unearned_step, protects: "the untouched one")
      dispose(value_reading(unearned_step, protects: "the reviewed one"), "accept")

      report = described_class.render(document)

      expect(report.index("the reviewed one")).to be < report.index("the untouched one")
    end

    it "renders no section at all when every reading was rejected" do
      dispose(value_reading(unearned_step), "reject")

      expect(described_class.render(document)).not_to include "What the unearned steps put first"
    end
  end

  # The section the architecture was rebuilt to make possible. Before a ruling
  # named its framework, a second premise's verdicts were indistinguishable from
  # the first premise's sentinel changing its mind, so the Lewisian run was
  # computed and thrown away rather than stored.
  describe "where different premises reach different verdicts" do
    let(:rival) { Framework.create!(key: "rival-fw", name: "Rival", version: "0", current: false) }

    it "says nothing at all when only one framework has ruled" do
      unearned_step

      expect(described_class.render(document)).not_to include "Where different premises"
    end

    it "reports both verdicts when two frameworks have ruled" do
      step = unearned_step
      step.record_verdict!("earned", asserter: sentinel, framework: rival)

      report = flat(described_class.render(document))

      expect(report).to include "Where different premises reach different verdicts"
      expect(report).to include "Rival"
      expect(report).to match(/interpretive → ontological/)
    end

    it "names the framework whose verdicts the step counts are" do
      unearned_step

      expect(flat(described_class.render(document))).to match(/These verdicts are .+'s\*\*, not the record's/)
    end

    it "refuses to rank the premises it reports" do
      step = unearned_step
      step.record_verdict!("earned", asserter: sentinel, framework: rival)

      report = flat(described_class.render(document))

      expect(report).to include "a fact about the **premises**, not about the text"
      expect(report).to include "Nothing in this system adjudicates between them"
    end

    it "reports a contested step rather than counting it as unearned" do
      other = Referent.create!(name: "Second", subject: "System", role: "Sentinel", primitive: "system")
      step = unearned_step
      step.record_verdict!("earned", asserter: other)

      report = flat(described_class.render(document))

      expect(step).to be_contested
      expect(report).to include "1 step is contested"
      expect(report).to include "no ground here for choosing between them"
    end

    it "calls one judge changing its own answer drift, not disagreement" do
      step = unearned_step
      step.record_verdict!("earned", asserter: sentinel)

      report = flat(described_class.render(document))

      expect(report).to include "drift rather than disagreement"
      expect(report).not_to include "is contested"
    end
  end

  # A claim two people typed differently is not settled by whoever read last,
  # and the report has to say the disagreement happened rather than showing a
  # category as though it had been agreed.
  describe "a claim two readers disagreed about" do
    let(:ana) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
    let(:bo)  { Referent.create!(name: "Bo", subject: "Person", role: "Reviewer", primitive: "person") }

    it "counts it and says a further reading is what settles it" do
      c = claim("Contested.", "interpretive")
      c.classify!(category("interpretive"), asserter: ana, confidence: 0.9)
      c.classify!(category("ontological"), asserter: bo, confidence: 0.9)

      report = flat(described_class.render(document))

      expect(c.reload).to be_contested
      expect(report).to include "| two readers disagreed | 1 |"
      expect(report).to include "a further independent reading"
    end

    it "does not count it among the claims that are typed" do
      c = claim("Contested.", "interpretive")
      c.classify!(category("interpretive"), asserter: ana, confidence: 0.9)
      c.classify!(category("ontological"), asserter: bo, confidence: 0.9)

      expect(flat(described_class.render(document))).to include "| claims typed | 0 of 1 |"
    end

    it "says nothing about disagreement when there is none" do
      claim("Plain.", "observation")

      expect(flat(described_class.render(document))).not_to include "a further independent reading"
    end
  end

  # This line read "N of M answers were inferred by an agent rather than decided
  # by a person" and could report nothing else: every resolution in the database
  # was asserted by the Sentinel whoever actually decided it.
  describe "who answered for a name" do
    let(:ana) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
    let(:agent) { Referent.create!(name: "Grounder", subject: "System", role: "Reviewer", primitive: "system") }
    let(:sentinel_ref) { Referent.find_by!(key: "identity-sentinel") }

    def resolve(text, by:, grounded:)
      m = claim("#{text} left.", "observation").mentions.create!(text: text)
      target = Referent.create!(name: text, subject: "Person", role: "Subject", primitive: "person")
      Assertion.create!(asserter: by, subject: m, object: target, act: "resolve",
                        claim: { "grounded" => grounded })
    end

    it "separates an automatic match from a person's decision" do
      resolve("Ada", by: sentinel_ref, grounded: false)
      resolve("Bea", by: ana, grounded: true)

      report = flat(described_class.render(document))

      expect(report).to include "1 was **matched by the resolver** without anyone being asked"
      expect(report).to include "1 was **grounded by a person** answering a STOP"
    end

    it "distinguishes an agent grounding under delegation from both" do
      resolve("Cyd", by: agent, grounded: true)

      expect(flat(described_class.render(document)))
        .to include "1 was **grounded by an agent** acting under delegation"
    end

    # A resolution predating the fix cannot say whether anybody was asked, and
    # reporting it as an automatic match would be inventing the answer.
    it "refuses to claim nobody was asked when the record does not say" do
      m = claim("Dee left.", "observation").mentions.create!(text: "Dee")
      target = Referent.create!(name: "Dee", subject: "Person", role: "Subject", primitive: "person")
      Assertion.create!(asserter: sentinel_ref, subject: m, object: target, act: "resolve", claim: {})

      report = flat(described_class.render(document))

      expect(report).to include "recorded before resolutions named their decider"
      expect(report).not_to include "without anyone being asked"
    end
  end

  describe "templates" do
    it "renders only the sections a template names" do
      claim("A claim.", "observation")
      value_reading(unearned_step)

      brief = described_class.render(document, template: "brief")

      expect(brief).to include "What kinds of claim it makes"
      expect(brief).not_to include "Where its claims rest"
    end

    it "refuses a template it does not have" do
      expect { described_class.render(document, template: "clinical") }
        .to raise_error(described_class::UnknownTemplate, /clinical/)
    end

    # Adding a section means building the measurement first. A template naming
    # one that has no source fails loudly rather than being filled with prose.
    it "refuses a template naming a section with no source" do
      stub_const("#{described_class}::TEMPLATES",
                 described_class::TEMPLATES.merge("invented" => %w[composition symbolic_density]))

      expect { described_class.render(document, template: "invented") }
        .to raise_error(described_class::UnsourcedSection, /symbolic_density/)
    end

    it "lists what it can render" do
      expect(described_class.templates).to include "epistemic-structure", "brief", "governance"
    end
  end

  describe "how it reads" do
    it "wraps prose to a consistent width, whatever the figures interpolated to" do
      3.times { claim("A claim.", "observation") }
      unearned_step

      lines = described_class.render(document).lines.map(&:chomp)
      prose = lines.reject { it.start_with?("|", "#", ">", "-") }.reject(&:empty?)

      expect(prose.map(&:length).max).to be <= MarkdownReflow::WIDTH
    end

    it "leaves its tables intact" do
      2.times { claim("A claim.", "observation") }

      expect(described_class.render(document)).to include "| Observation | 2 | 100.0% |"
    end
  end

  describe "the limits it reports" do
    it "derives the instability figure from this document rather than asserting one" do
      claim("Stable.", "observation", readings: 3)
      claim("Unstable.", "observation", readings: 1)

      expect(flat(described_class.render(document)))
        .to match(/roughly 50% of this document's claims were read differently/)
    end

    it "says plainly that nothing here establishes truth" do
      claim("A claim.", "observation")

      expect(flat(described_class.render(document))).to include "never whether it is right"
    end
  end
end
