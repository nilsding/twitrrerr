require 'sqlite3'

module Twitrrerr
  # Provides a SQLite3 database connection.
  class Database
    # Path to the database file.
    DATABASE_FILE = File.expand_path('twitrrerr.db', Twitrrerr::CONFIG_PATH)

    class << self
      attr_reader :db

      # Initializes a database connection and loads a database schema.
      def init
        @db ||= SQLite3::Database.new(DATABASE_FILE)
        db.execute_batch schema
      end

      private
        :db

      # Returns the database schema.
      # @return [String] The current database schema
      def schema
        <<-SQL
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY,
  screen_name TEXT,
  access_token TEXT,
  access_secret TEXT
);
        SQL
      end
    end
  end
end

