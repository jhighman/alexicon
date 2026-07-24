# Be sure to restart your server when you modify this file.

# "Evidence" is uncountable. Without this, Rails names the table `evidences`,
# which is not a word anyone uses about evidence.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "evidence"
end
