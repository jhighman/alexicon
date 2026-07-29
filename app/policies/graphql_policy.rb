# Reading the graph asks the same capability question reading a document does.
# Nothing here is a second authorisation path; it is the same one, reached
# through a different verb.
class GraphqlPolicy < ApplicationPolicy
  def query? = user&.can_view? || false
end
