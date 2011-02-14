require "sequel"
require "sequel/extensions/migration"

DB=Sequel.sqlite 'songs.sqlite3'
Sequel.migration do
    up do
      create_table(:albums) do
        primary_key :id
        String :name
      end
    end

    down do
      drop_table(:albums)
    end
  end

