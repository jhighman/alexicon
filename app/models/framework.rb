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
end
