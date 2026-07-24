class LlmAssignmentsController < ApplicationController
  def create
    @assignment = LlmAssignment.new(assignment_params.merge(created_by: current_reviewer))
    authorize @assignment

    if @assignment.save
      redirect_to llm_models_path, notice: "Routing #{@assignment.scope_description}."
    else
      redirect_to llm_models_path, alert: @assignment.errors.full_messages.to_sentence
    end
  end

  def destroy
    assignment = LlmAssignment.find(params[:id])
    authorize assignment

    assignment.destroy
    redirect_to llm_models_path, notice: "Routing removed."
  end

  private

  def assignment_params
    params.require(:llm_assignment).permit(:llm_model_id, :agent_pattern, :action_type, :priority)
  end
end
