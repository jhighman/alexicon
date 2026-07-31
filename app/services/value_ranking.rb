# An ordering over a value set, assembled from probes that held still.
#
# Three conditions have to hold before pairwise judgements can be ranked at all,
# and this refuses rather than interpolates when any of them fails:
#
#   1. A SHARED VOCABULARY. The step-value layer failed here outright — 25
#      readings naming 50 distinct terms in 50 slots, zero repeated. Probes carry
#      values from the framework's own vocabulary, so this one holds by
#      construction.
#   2. A CONNECTED GRAPH. Four probes over four disjoint pairs is four
#      disconnected edges, and no ordering follows from it however stable each
#      edge is. Knowing Safety > Autonomy and Kindness > Truth relates the two
#      not at all.
#   3. TRANSITIVITY, which is NOT assumed. If Truth beats Kindness, Kindness
#      beats Belonging and Belonging beats Truth, that may be a real property of
#      a value system — priority that is context-dependent rather than
#      hierarchical — and forcing a total order destroys exactly the finding.
#
# So the output is an order over STRONGLY CONNECTED COMPONENTS, not over values.
# A component with one member is a value with a settled position. A component
# with several is a cycle, reported as a cycle and left unresolved. That is the
# same discipline as `Transition::CONTESTED`: the state of there being no ground
# for choosing is reported instead of a verdict, never as one.
#
# Every edge is gated on `OrderStability` first. A probe whose ordering moves
# between runs has established nothing, and an edge built from it would be an
# artefact of one run. Excluded edges are reported rather than dropped quietly —
# a ranking that silently omits what it could not measure reads as a ranking over
# everything.
#
# Nothing here calls a model. It re-reads standing interpretations, so the same
# evidence can be re-examined without being re-bought.
class ValueRanking
  Edge = Data.define(:probe, :first, :second, :agreement, :runs)
  Excluded = Data.define(:probe, :reason, :runs, :agreement)

  Result = Data.define(:model, :edges, :excluded, :groups, :components, :fragile, :vocabulary,
                       :islands) do
    # A cycle: several values with no ground for choosing between them.
    def cycles = groups.select { it.size > 1 }
    def ranked? = components == 1 && cycles.empty? && groups.any?
    def ranked_values = groups.flatten
    def unranked = vocabulary - ranked_values

    # The order is only meaningful WITHIN a connected component, and `groups` is
    # a flat sequence across all of them. Rendering that sequence as one list is
    # an arbitrary concatenation presented as a hierarchy — the first draft of
    # the rake task did exactly that, printing eight values as a numbered
    # ordering when the graph was four disjoint pairs.
    #
    # So the flat sequence is not the thing to display. `islands` is: the
    # orderings that actually hold, each one self-contained, with nothing
    # implied between them.
    def orderings = islands

    # The order is only meaningful within a connected component, so a partial
    # result says so rather than presenting the concatenation as a hierarchy.
    def verdict
      return "no stable edges — nothing to rank" if groups.empty?
      return "not connected — #{components} components, no ordering spans them" if components > 1
      return "#{cycles.size} cycle(s) — reported, not resolved" if cycles.any?

      "ranked over #{ranked_values.size} values"
    end
  end

  def self.for(model:, probes: ValueProbe.active, vocabulary: FrameworkValue.vocabulary)
    new(model: model, probes: probes, vocabulary: vocabulary).call
  end

  def initialize(model:, probes:, vocabulary:)
    @model = model
    @probes = probes.to_a
    @vocabulary = vocabulary.map(&:name)
  end

  def call
    included, excluded = partition_edges

    order = topological(included)
    membership = component_of(included)
    Result.new(model: model, edges: included, excluded: excluded, groups: order,
               components: membership.values.uniq.size, fragile: fragile(included),
               vocabulary: vocabulary, islands: split_by_component(order, membership))
  end

  # The orderings that actually hold, one per connected component, each ordered
  # within itself and carrying no implication about any other.
  def split_by_component(order, membership)
    order.group_by { membership[it.first] }.values
  end

  # A hierarchy is a claim about what a model IS, which is a proposal for a
  # person to accept rather than something a service may assert. Recorded open,
  # so it carries a disposition and somebody's name if it is ever relied on.
  def self.propose!(result, by:)
    Assertion.create!(
      asserter: by, subject: result.model, act: "assert",
      claim: { "proposal" => "value ordering", "verdict" => result.verdict,
               "groups" => result.groups, "ranked" => result.ranked?,
               "edges" => result.edges.size, "excluded" => result.excluded.size,
               "fragile" => result.fragile }
    )
  end

  private

  attr_reader :model, :probes, :vocabulary

  def partition_edges
    included = []
    excluded = []

    probes.each do |probe|
      stability = OrderStability.for(probe: probe, model: model)
      reason = exclusion_reason(stability)
      if reason
        excluded << Excluded.new(probe: probe, reason: reason, runs: stability.runs,
                                 agreement: stability.agreement)
        next
      end

      first, second = stability.majority.split(" > ")
      included << Edge.new(probe: probe, first: first, second: second,
                           agreement: stability.agreement, runs: stability.runs)
    end

    [ included, excluded ]
  end

  def exclusion_reason(stability)
    return "no readings" if stability.runs.zero?
    return "only #{stability.runs} run(s); 3 needed" if stability.runs < 3
    return "unstable — #{stability.describe_agreement}" unless stability.stable?

    nil
  end

  # Tarjan's strongly connected components, then a topological order over the
  # condensation. A component of size one is a value with a settled position; a
  # larger one is a cycle, and the pair of them being in the same component IS
  # the finding.
  def topological(edges)
    nodes = edges.flat_map { [ it.first, it.second ] }.uniq
    adjacency = nodes.to_h { |n| [ n, edges.select { it.first == n }.map(&:second) ] }
    components = tarjan(nodes, adjacency)

    index = {}
    components.each_with_index { |group, i| group.each { index[it] = i } }

    # Condensation edges, then Kahn's algorithm over them.
    incoming = Array.new(components.size, 0)
    outgoing = Array.new(components.size) { [] }
    edges.each do |edge|
      from = index[edge.first]
      to = index[edge.second]
      next if from == to || outgoing[from].include?(to)

      outgoing[from] << to
      incoming[to] += 1
    end

    kahn(components, incoming, outgoing)
  end

  def kahn(components, incoming, outgoing)
    ready = (0...components.size).select { incoming[it].zero? }
    order = []

    until ready.empty?
      current = ready.shift
      order << components[current]
      outgoing[current].each do |nxt|
        incoming[nxt] -= 1
        ready << nxt if incoming[nxt].zero?
      end
    end

    order
  end

  def tarjan(nodes, adjacency)
    state = { index: {}, low: {}, stack: [], on_stack: {}, counter: 0, components: [] }
    nodes.each { strongconnect(it, adjacency, state) unless state[:index].key?(it) }
    state[:components]
  end

  def strongconnect(node, adjacency, state)
    state[:index][node] = state[:low][node] = state[:counter]
    state[:counter] += 1
    state[:stack].push(node)
    state[:on_stack][node] = true

    adjacency.fetch(node, []).each do |neighbour|
      if !state[:index].key?(neighbour)
        strongconnect(neighbour, adjacency, state)
        state[:low][node] = [ state[:low][node], state[:low][neighbour] ].min
      elsif state[:on_stack][neighbour]
        state[:low][node] = [ state[:low][node], state[:index][neighbour] ].min
      end
    end

    return unless state[:low][node] == state[:index][node]

    component = []
    loop do
      popped = state[:stack].pop
      state[:on_stack][popped] = false
      component << popped
      break if popped == node
    end
    state[:components] << component
  end

  # Undirected connectivity, which decides whether an ordering spans the set at
  # all. A topological sort of a disconnected graph still returns a sequence, and
  # that sequence would be an arbitrary concatenation presented as a hierarchy.
  def component_of(edges)
    nodes = edges.flat_map { [ it.first, it.second ] }.uniq
    return {} if nodes.empty?

    parent = nodes.to_h { [ it, it ] }
    root = lambda do |x|
      x = parent[x] while parent[x] != x
      x
    end
    edges.each { parent[root.call(it.first)] = root.call(it.second) }

    nodes.to_h { [ it, root.call(it) ] }
  end

  # Values whose position rests on a single probe. Not an error — a spanning tree
  # is all a minimal probe set can give — but a value here moves if one probe
  # turns out unstable, and a ranking that did not say so would present a leaf
  # with the same authority as a value fixed by four independent probes.
  def fragile(edges)
    edges.flat_map { [ it.first, it.second ] }.tally.select { |_, n| n == 1 }.keys
  end
end
