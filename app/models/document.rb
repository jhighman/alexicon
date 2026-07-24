# A text submitted for analysis. The original body is never mutated -- claims
# reference it by offset, so the source stays auditable.
class Document < ApplicationRecord
  has_many :claims, -> { order(:position) }, dependent: :destroy
  has_many :transitions, dependent: :destroy

  validates :body, presence: true

  def flags = SentinelFlag.joins(:transition).where(transitions: { document_id: id })
end
