module ActiveRecord
  ###
  # This class encapsulates a Result returned from calling +exec_query+ on any
  # database connection adapter. For example:
  #
  #   result = ActiveRecord::Base.connection.exec_query('SELECT id, title, body FROM posts')
  #   result # => #<ActiveRecord::Result:0xdeadbeef>
  #
  #   # Get the column names of the result:
  #   result.columns
  #   # => ["id", "title", "body"]
  #
  #   # Get the record values of the result:
  #   result.rows
  #   # => [[1, "title_1", "body_1"],
  #         [2, "title_2", "body_2"],
  #         ...
  #        ]
  #
  #   # Get an array of hashes representing the result (column => value):
  #   result.to_hash
  #   # => [{"id" => 1, "title" => "title_1", "body" => "body_1"},
  #         {"id" => 2, "title" => "title_2", "body" => "body_2"},
  #         ...
  #        ]
  #
  #   # ActiveRecord::Result also includes Enumerable.
  #   result.each do |row|
  #     puts row['title'] + " " + row['body']
  #   end
  class Result
    include Enumerable

    IDENTITY_TYPE = Class.new { def type_cast(v); v; end }.new # :nodoc:

    attr_reader :columns, :rows, :column_types

    def initialize(columns, rows, column_types = {})
      @columns      = columns
      @rows         = rows
      @hash_rows    = nil
      @column_types = column_types
    end

    def identity_type # :nodoc:
      IDENTITY_TYPE
    end

    def each
      if block_given?
        hash_rows.each { |row| yield row }
      else
        hash_rows.to_enum
      end
    end

    def to_hash
      hash_rows
    end

    alias :map! :map
    alias :collect! :map

    # Returns true if there are no records.
    def empty?
      rows.empty?
    end

    def to_ary
      hash_rows
    end

    def [](idx)
      hash_rows[idx]
    end

    def last
      hash_rows.last
    end

    def initialize_copy(other)
      @columns   = columns.dup
      @rows      = rows.dup
      @hash_rows = nil
    end

    private

    def hash_rows
      @hash_rows ||=
        begin
          # We freeze the strings to prevent them getting duped when
          # used as keys in ActiveRecord::Base's @attributes hash
          columns = @columns.map { |c| c.dup.freeze }
          @rows.map { |row|
            Hash[columns.zip(row)]
          }
        end
    end
  end
end
