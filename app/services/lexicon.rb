# The vocabulary of the system, as a document, from the record.
#
# Three properties were asked of it, and each is machinery here rather than a
# claim the document makes about itself:
#
#   EXHAUSTIVE — every key the system actually uses appears. The sources are
#     enumerated in `SOURCES`, read at render time, and a spec fails when
#     something in one of them has no entry. Adding a category or a delegated
#     act breaks the suite until the word is defined.
#
#   MUTUALLY EXCLUSIVE — a term belongs to exactly one cluster and has exactly
#     one kind. Nothing is filed twice.
#
#   NON-OVERLAPPING — this one could not simply be asserted, because the
#     vocabulary is NOT non-overlapping and pretending otherwise would be the
#     error the framework is named for. `observation` is a claim category and a
#     flow stage. `assertion` is a flow stage and the name of the single record
#     type. So a word used by more than one term must carry an explicit
#     `distinct_from`, naming the other and saying what separates them — and a
#     collision without one fails the suite. Overlap is not forbidden; it is
#     forbidden to be silent.
#
# Hand-writing this was the alternative and it would have drifted inside a week,
# the way BASELINE.md drifted inside a day. What cannot be derived — the
# concepts with no row and no constant — is authored, and each authored entry
# names where it lives in the code so a reader can check it.
class Lexicon
  Term = Data.define(:key, :name, :cluster, :kind, :definition, :distinct_from, :see_also, :source) do
    def word = name.to_s.downcase.strip
  end

  # Order is the reading order of the document.
  CLUSTERS = [
    [ "record", "The record", "One record type, and what can be said with it." ],
    [ "identity", "Identity", "Who or what a name refers to, and what may be said of it." ],
    [ "claim", "Kinds of claim", "What a statement DOES, never how true it is." ],
    [ "step", "Steps between claims", "The unit of governance is the move, not the claim." ],
    [ "value", "What a step protects", "Beneath judgement: the commitments a move puts first." ],
    [ "actor", "Who decides", "Attribution, capability, and delegated judgement." ],
    [ "measure", "Measurement", "What the system has established about itself." ],
    [ "frame", "The framework", "The seeded structure everything above is read against." ]
  ].freeze

  # Where the generated terms come from. A spec walks these and fails on any key
  # without an entry, which is what makes "exhaustive" checkable.
  def self.sources
    fw = Framework.current!
    {
      "claim category" => fw.claim_categories.map { [ it.key, it.name, it.definition ] },
      "flow stage" => fw.flow_stages.map { [ it.key, it.name, nil ] },
      "domain" => fw.domains.map { [ it.key, it.name, it.question ] },
      "value" => FrameworkValue.vocabulary.map { [ it.key, it.name, it.definition ] },
      "act" => Assertion::ACTS.map { [ it, it, nil ] },
      "severity" => Assertion::SEVERITIES.map { [ it, it, nil ] },
      "verdict" => Transition::VERDICTS.map { [ it, it, nil ] },
      "delegable act" => Delegation::ACTS.map { [ it, it.humanize.downcase, nil ] },
      "role" => Capabilities::ROLES.map { [ it, it, nil ] },
      "mention status" => Mention::STATUSES.map { [ it, it.humanize.downcase, nil ] },
      "model status" => LlmModel::STATUSES.map { [ it, it, nil ] }
    }
  end

  def self.render = new.render

  def render
    [ header, contents, *CLUSTERS.map { cluster_section(it) }, collisions_section, provenance ]
      .compact.join("\n\n")
      .then { MarkdownReflow.call(it) }
  end

  def terms = @terms ||= (Authored::TERMS + generated).sort_by { [ cluster_index(it), it.name.downcase ] }

  # A word carried by more than one term. Not an error — the vocabulary really
  # does reuse words — but every one of them must say so.
  def collisions
    terms.group_by(&:word).select { |_, group| group.size > 1 }
  end

  private

  def cluster_index(term) = CLUSTERS.index { it.first == term.cluster } || 99

  def generated
    self.class.sources.flat_map do |kind, rows|
      rows.filter_map do |key, name, definition|
        next if Authored::TERMS.any? { it.key == "#{kind}:#{key}" }

        Term.new(key: "#{kind}:#{key}", name: name.to_s.humanize.sub(/\A\w/, &:upcase),
                 cluster: Authored::CLUSTER_FOR.fetch(kind), kind: kind,
                 definition: definition.presence || Authored::GENERATED_GLOSS.fetch("#{kind}:#{key}", nil),
                 distinct_from: Authored::DISTINCTIONS["#{kind}:#{key}"], see_also: [], source: "record")
      end
    end
  end

  def header
    <<~MD.strip
      # Lexicon

      **The vocabulary of the Alexicon, from the record · #{terms.size} terms · #{Time.current.to_date.to_fs(:long)}**

      *Generated. Re-render with `rake alexicon:lexicon`.*

      Every term the system actually uses appears here, because the list is read
      from the framework's own data and from the constants that define its acts,
      verdicts and roles. Adding a category or a delegated act fails the test suite
      until the word is defined, which is what makes this exhaustive rather than
      merely long.

      Each term sits in exactly one cluster and has exactly one kind. Where two
      terms share a word — and several do — both say so and say what separates
      them. The vocabulary is not non-overlapping; it is not allowed to overlap
      **silently**, which is the same distinction the framework draws everywhere
      else.
    MD
  end

  def contents
    rows = CLUSTERS.map do |key, name, gloss|
      count = terms.count { it.cluster == key }
      "| [#{name}](##{name.parameterize}) | #{count} | #{gloss} |"
    end
    [ "| Cluster | Terms | |", "|---|---|---|", *rows ].join("\n")
  end

  def cluster_section(cluster)
    key, name, gloss = cluster
    members = terms.select { it.cluster == key }
    return nil if members.empty?

    [ "## #{name}", "*#{gloss}*", *members.map { entry(it) } ].join("\n\n")
  end

  def entry(term)
    lines = [ "### #{term.name}", "*#{term.kind}*" ]
    lines << (term.definition.presence || "_No definition recorded._")
    lines << "**Distinct from #{term.distinct_from}**" if term.distinct_from.present?
    lines << "See also: #{term.see_also.join(', ')}." if term.see_also.any?
    lines.join("\n\n")
  end

  def collisions_section
    return nil if collisions.empty?

    rows = collisions.map do |word, group|
      "| #{word} | #{group.map { "#{it.name} (#{it.kind})" }.join(' · ')} |"
    end

    <<~MD.strip
      ## Words carried by more than one term

      The vocabulary reuses words. That is not a defect to be tidied away — a flow
      stage called *observation* and a claim category called *observation* are
      genuinely different things, and renaming either would lose the reason both
      are called that. What is forbidden is carrying the overlap silently, so every
      term below names the other and says what separates them.

      | Word | Terms |
      |---|---|
      #{rows.join("\n")}
    MD
  end

  def provenance
    generated_count = terms.count { it.source == "record" }

    <<~MD.strip
      ---

      ## Where these came from

      | | |
      |---|---|
      | read from the framework's data or a code constant | #{generated_count} |
      | authored, because nothing in the system holds them | #{terms.size - generated_count} |

      A generated term cannot drift from what the system does, because it is what
      the system does. An authored one can, so each names the file it describes and
      is worth checking against it.
    MD
  end
end
