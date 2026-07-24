# A name a term has also gone by, and where that usage appears.
class TermAlias < ApplicationRecord
  belongs_to :term

  validates :name, presence: true
end
