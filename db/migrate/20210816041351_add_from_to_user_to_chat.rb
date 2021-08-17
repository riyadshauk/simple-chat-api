# https://stackoverflow.com/questions/2166613/multiple-foreign-keys-referencing-the-same-table-in-ror
# https://edgeguides.rubyonrails.org/active_record_migrations.html#creating-a-standalone-migration
# https://edgeapi.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_table

class AddFromToUserToChat < ActiveRecord::Migration[6.1]
  change_table :chats do |t|
    t.references :from
    t.references :to
  end
end
