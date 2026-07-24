# Answering a flag.
#
# A disposition does not decide whether a claim is true. It records that a
# person looked at the flag and either let it stand or set it aside — and it is
# written as a further assertion about the flag, never as an edit to it.
class FlagsController < ApplicationController
  def update
    flag = Assertion.flags.find(params[:id])
    authorize flag, policy_class: FlagPolicy
    disposition = params[:disposition].to_s

    flag.dispose!(as: disposition, by: current_reviewer)
    redirect_back fallback_location: root_path,
                  notice: "Recorded: #{current_reviewer.name} #{disposition} this flag."
  rescue ArgumentError
    redirect_back fallback_location: root_path,
                  alert: "#{disposition.inspect} is not a disposition."
  end
end
