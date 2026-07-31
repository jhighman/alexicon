# A bounded episode of a document: the unit judgment waits for.
#
# A jury does not hear sentence one, verdict, sentence two, verdict. It hears
# the whole case, deliberates, and only then judges — because the ending is
# allowed to reinterpret the beginning. A father inventing a game inside a camp
# is lying at every step, and the lie is not what the episode establishes; a
# judge scoped to the sentence sees the untruth, and only a judge scoped to the
# closed episode can see what it was for. The unit that makes such a judgement
# expressible is the case, and this is that unit.
#
# It is a Relationship, like Transition, because it is the same construct: an
# independently governable edge between two claims — here the first and last of
# an episode — with a standing derived from accountable assertions.
#
# **Closure is the constructor, not a gate.** A case does not carry an `open`
# flag that a judge must remember to check; a case that has not closed does not
# exist. `derive!` creates a case only where its right boundary is established —
# a structural claim (a heading restarts an argument; a signature ends a
# letter), or the end of a completed document. In a document still growing, the
# final run of claims is not a case yet, and nothing can be asked about it. The
# invariant "judgment waits for closure" is enforced by what can be
# constructed, which is where this codebase puts its guards.
#
# The boundaries come from structure, which ingest already marks and which is
# deliberately rule-based: where an episode begins and ends is a decision
# everything downstream inherits, so it is not a model's to make.
class Case < Relationship
  KIND = "case_closure".freeze

  before_validation :default_kind

  # Derives every closed episode: maximal runs of substantive claims between
  # structural boundaries. Idempotent — re-deriving finds the same cases.
  #
  # `complete:` says whether the document has ended. A completed document's
  # final run is closed by the document ending; a growing one's is not a case
  # yet. Documents in this application are complete at ingest, so the default
  # is the truth here — the parameter exists because the composition scenario
  # (CONOPS 6.2) reads text that is still being written.
  #
  # A run of one claim has no step inside it to judge and no move for an ending
  # to reinterpret, and an edge from a claim to itself is not an edge.
  def self.derive!(document, complete: true)
    claims = document.claims.order(:position).to_a
    runs = claims.chunk_while { |a, b| !a.structural && !b.structural }
                 .map { |run| run.reject(&:structural) }
                 .reject(&:empty?)
    runs.pop if !complete && !claims.last&.structural

    runs.select { it.size >= 2 }.map do |run|
      find_or_create_by!(kind: KIND, source: run.first, target: run.last)
    end
  end

  def document = source&.document

  def opening = source
  def closing = target

  # Every substantive claim of the episode, in order.
  def claims
    document.claims.substantive
            .where(position: opening.position..closing.position).order(:position)
  end

  # Every step whose both feet are inside the episode.
  def steps
    span = opening.position..closing.position
    document.transitions.select do
      span.cover?(it.from_claim.position) && span.cover?(it.to_claim.position)
    end
  end

  def include?(step)
    return false if step.from_claim&.document != document

    span = opening.position..closing.position
    span.cover?(step.from_claim.position) && span.cover?(step.to_claim.position)
  end

  def to_s = "case #{id}: claims #{opening.position}–#{closing.position}"

  private

  def default_kind
    self.kind ||= KIND
  end
end
