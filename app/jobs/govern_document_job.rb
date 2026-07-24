# Judging is a separate job from classifying, on purpose.
#
# Chapter 6's independence requirement is about the actor, not the schedule --
# and the actors are already distinct referents. Keeping the steps separate
# means a person can read the classifications before anything rules on the
# promotions between them, which is the order the framework describes.
class GovernDocumentJob < ApplicationJob
  queue_as :default

  discard_on Document::ExecutionLocked
  discard_on GovernanceSentinel::NotIndependent

  def perform(document)
    GovernanceSentinel.review_document!(document)
  end
end
