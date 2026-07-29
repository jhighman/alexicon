# The GraphQL endpoint. Same token, same Referent, same policies.
#
# There is no second authorisation path: a token answers the capability
# questions a User answers, through the same `Capabilities` module, and the
# schema exposes only what a viewer may already read in the browser. The one
# exception asks for itself — a baseline measurement needs the role that may see
# the model registry.
class Api::V1::GraphqlController < Api::V1::BaseController
  def execute
    authorize :graphql, :query?

    result = AlexiconSchema.execute(
      params[:query],
      variables: params[:variables] || {},
      operation_name: params[:operationName],
      context: { token: current_token, reviewer: current_reviewer }
    )
    render json: result
  rescue GraphQL::ParseError, GraphQL::ExecutionError => e
    render json: { errors: [ { message: e.message } ] }, status: :bad_request
  end
end
