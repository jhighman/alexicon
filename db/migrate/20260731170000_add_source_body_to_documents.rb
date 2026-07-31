# The text as it arrived, kept beside the text claims are offset against.
#
# Ingest now unwraps hard-wrapped prose before segmenting (ADR 23), so `body`
# is a normalised form rather than the bytes somebody submitted. Keeping the
# original is what makes that transformation auditable instead of destructive:
# the source is still there, and the normalisation can be re-derived from it and
# checked.
#
# NULL means the document predates the change and its `body` IS its source.
# Existing rows are deliberately NOT backfilled and NOT re-segmented — their
# claims are recorded measurements, and re-deriving them would silently move
# every figure taken from them.
class AddSourceBodyToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :source_body, :text
  end
end
