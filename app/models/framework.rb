# A version of the Alexicon framework itself. The framework has already moved
# once (G3/G7 -> 2.0); storing it lets both versions coexist while claims
# classified under the old vocabulary stay meaningful.
class Framework < ApplicationRecord
  has_many :domains, -> { order(:position) }, dependent: :destroy
  has_many :claim_categories, -> { order(:position) }, dependent: :destroy
  has_many :flow_stages, -> { order(:position) }, dependent: :destroy

  validates :key, :name, :version, presence: true
  validates :key, uniqueness: true

  scope :current, -> { where(current: true) }

  def self.current!
    current.first or raise ActiveRecord::RecordNotFound, "no current framework"
  end

  # The current framework, or nil when none is declared.
  #
  # `current!` raises, which is right for anything that must judge under stated
  # premises. This is for the reads and records that have to work in a database
  # where no framework has been declared at all: there, a ruling is UNATTRIBUTED
  # rather than Humean, and nil is its bucket. Unattributed rulings are never
  # absorbed into a named framework's answer — that absorption is exactly the
  # confusion this distinction exists to prevent.
  def self.current_or_none = current.first
end
