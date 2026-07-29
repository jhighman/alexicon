require "rails_helper"

# Three properties were asked of this vocabulary. Each is checked here rather
# than claimed in the document, because a lexicon that asserts its own
# exhaustiveness is the kind of stored summary this project exists to distrust.
RSpec.describe Lexicon do
  before { seed_quietly }

  let(:lexicon) { described_class.new }
  let(:terms) { lexicon.terms }

  # EXHAUSTIVE. Adding a category, a delegated act or a value fails this until
  # the word is defined.
  describe "exhaustiveness" do
    it "defines every key the system actually uses" do
      described_class.sources.each do |kind, rows|
        rows.each do |key, _name, _definition|
          expect(terms.map(&:key)).to include("#{kind}:#{key}"),
                                      "#{kind} #{key.inspect} has no entry in the lexicon"
        end
      end
    end

    it "covers every source the system enumerates" do
      expect(described_class.sources.keys).to include(
        "claim category", "flow stage", "domain", "value", "act", "severity",
        "verdict", "delegable act", "role", "mention status", "model status"
      )
    end

    it "leaves no term without a definition" do
      undefined = terms.select { it.definition.blank? }

      expect(undefined.map(&:key)).to be_empty
    end
  end

  # MUTUALLY EXCLUSIVE. A term is filed once, in one cluster, with one kind.
  describe "mutual exclusivity" do
    it "gives every term a unique key" do
      duplicates = terms.map(&:key).tally.select { |_, n| n > 1 }

      expect(duplicates).to be_empty
    end

    it "files every term in exactly one known cluster" do
      known = described_class::CLUSTERS.map(&:first)

      expect(terms.map(&:cluster).uniq - known).to be_empty
    end

    it "never authors a term the record already generates" do
      authored = described_class::Authored::TERMS.map(&:key)
      generated = terms.reject { it.source == "authored" }.map(&:key)

      expect(authored & generated).to be_empty
    end
  end

  # NON-OVERLAPPING, and this is the one that could not be asserted. The
  # vocabulary DOES reuse words — `observation` is a claim category and a flow
  # stage, `assertion` is a flow stage and the record type. Overlap is allowed;
  # silent overlap is not.
  describe "overlap" do
    it "finds the collisions rather than hiding them" do
      expect(lexicon.collisions.keys).to include "observation", "assertion"
    end

    it "requires every side of a collision to say what separates it from the other" do
      silent = lexicon.collisions.reject { |_, group| group.all? { it.distinct_from.present? } }

      expect(silent.keys).to be_empty,
                             "these words are carried by more than one term with no distinction " \
                             "declared: #{silent.keys.join(', ')}"
    end

    it "names the other term in each distinction, not just the difference" do
      lexicon.collisions.each_value do |group|
        group.each do |term|
          others = group.reject { it.key == term.key }.map { it.kind }

          expect(term.distinct_from).to include(*others.map { it.split.first }),
                                        "#{term.key} does not name what it is distinct from"
        end
      end
    end
  end

  describe "the rendered document" do
    subject(:document) { described_class.render }

    it "leads with what makes it exhaustive rather than claiming it is" do
      expect(document).to include "fails the test suite"
    end

    it "carries a section for every non-empty cluster" do
      described_class::CLUSTERS.each do |key, name, _gloss|
        next if terms.none? { it.cluster == key }

        expect(document).to include "## #{name}"
      end
    end

    it "shows the collisions as a table rather than burying them in the entries" do
      expect(document).to include "## Words carried by more than one term"
      expect(document).to match(/\| observation \|/)
    end

    it "says how much of itself was generated and how much authored" do
      expect(document).to match(/read from the framework's data or a code constant \| \d+/)
      expect(document).to match(/authored, because nothing in the system holds them \| \d+/)
    end

    it "renders every term it holds" do
      terms.each { expect(document).to include("### #{it.name}") }
    end

    it "wraps like the other generated documents" do
      prose = document.lines.map(&:chomp)
                      .reject { it.start_with?("|", "#", ">", "-") }.reject(&:empty?)

      expect(prose.map(&:length).max).to be <= MarkdownReflow::WIDTH
    end
  end
end
