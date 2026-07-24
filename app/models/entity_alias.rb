# A surface form referring to an entity.
#
# `ambiguous` marks a form known to carry non-entity senses as well --
# "Wednesday" is a daughter and also a weekday. Such a form never resolves
# silently, however few entity candidates it matches.
class EntityAlias < ApplicationRecord
  belongs_to :entity

  validates :name, presence: true
  validates :name, uniqueness: { scope: :entity_id, case_sensitive: false }

  scope :ambiguous, -> { where(ambiguous: true) }
end
