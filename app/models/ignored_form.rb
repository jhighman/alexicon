# A surface form a person has judged not to be a subject.
#
# This is the extractor's memory. It cannot tell a drug name from a person's
# name — both are capitalised words it has never seen — so it asks once and
# does not ask again.
class IgnoredForm < ApplicationRecord
  belongs_to :decided_by, class_name: "Referent", optional: true

  validates :form, presence: true
  validates :form, uniqueness: { case_sensitive: false }

  scope :matching, ->(text) { where("LOWER(form) = ?", text.to_s.downcase) }

  def self.ignores?(text) = matching(text).exists?

  def self.forms = pluck(:form)
end
