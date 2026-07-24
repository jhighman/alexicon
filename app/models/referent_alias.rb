# A surface form referring to an entity.
#
# `ambiguous` marks a form known to carry non-entity senses as well --
# "Wednesday" is a daughter and also a weekday. Such a form never resolves
# silently, however few entity candidates it matches.
class ReferentAlias < ApplicationRecord
  belongs_to :referent

  validates :name, presence: true
  validates :name, uniqueness: { scope: :referent_id, case_sensitive: false }

  scope :ambiguous, -> { where(ambiguous: true) }
end
