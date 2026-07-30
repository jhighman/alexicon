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
      expect(flat(report)).to include "never as findings"
    end

    it "counts how many steps it actually read, against how many were flagged" do
      first = unearned_step
      unearned_step
      value_reading(first)

      expect(described_class.render(document)).to match(/Read at 1 of the 2 unearned steps/)
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
