# The read layer over the assertion graph.
#
# REST answers "this document, then its claims, then every assertion about each
# claim, then the challenges to those" in as many round trips as there are
# levels. The record is recursive by construction — assertions about assertions
# — and this is the surface that shape actually suits.
#
# QUERIES ONLY, and deliberately. Writing goes through REST, where the
# delegation gate lives: an agent's judgement needs a standing decision by a
# named person before it counts. Putting mutations here would mean a second
# write path to keep in step with that gate, and two authorisation paths is one
# more than this system is willing to have.
#
# The recursion that makes the layer worth building is also what makes it
# dangerous. `assertions { assertions { assertions … } }` is unbounded by
# nature, so the limits below are load-bearing rather than boilerplate.
class AlexiconSchema < GraphQL::Schema
  query Types::QueryType

  max_depth 12
  max_complexity 400
  default_max_page_size 200

  # A query that asks for too much is a mistake to be told about, not a request
  # to be truncated into a plausible-looking partial answer.
  def self.type_error(err, context)
    raise GraphQL::ExecutionError, "Unresolvable type: #{err.message}"
  end
end
