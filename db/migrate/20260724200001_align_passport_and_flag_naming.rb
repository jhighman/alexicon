# The Cognitive Passport is Name -> Subject -> Role. The middle level was
# modelled as `category`, which is neither the framework's word nor free of
# confusion with ClaimCategory.
#
# Adopting "subject" for the passport level frees nothing on its own, because
# SentinelFlag already used `subject` for its polymorphic target. That one
# becomes `flaggable` -- a technical term carrying no framework meaning -- so
# "subject" means exactly one thing in this codebase.
class AlignPassportAndFlagNaming < ActiveRecord::Migration[8.1]
  def change
    rename_column :entities, :category, :subject
    rename_column :sentinel_flags, :subject_type, :flaggable_type
    rename_column :sentinel_flags, :subject_id, :flaggable_id
  end
end
