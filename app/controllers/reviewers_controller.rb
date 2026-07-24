# Establishes who is answering a flag.
#
# Deliberately not authentication. The architecture requires every judgement to
# have an accountable author; this supplies the name. Whether that person is
# entitled to answer is a separate question this does not attempt.
class ReviewersController < ApplicationController
  def new
    @reviewer = Referent.new
  end

  def create
    name = params.require(:referent).permit(:name)[:name].to_s.strip

    if name.blank?
      @reviewer = Referent.new
      flash.now[:alert] = "A name is required — dispositions are recorded against it."
      return render :new, status: :unprocessable_content
    end

    reviewer = Referent.find_or_initialize_by(name: name, primitive: "person")
    reviewer.update!(subject: "Person", role: "Reviewer")
    session[:reviewer_id] = reviewer.id

    redirect_to(session.delete(:return_to) || root_path,
                notice: "Signed in as #{reviewer.name}. Your dispositions will be recorded under this name.")
  end

  def destroy
    session.delete(:reviewer_id)
    redirect_to root_path, notice: "Signed out."
  end
end
