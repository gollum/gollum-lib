module Gollum
  module Sorters
    class WikiSorter
      SORT_CREATED_AT = "created_at".freeze

      attr_reader :sort, :direction_desc, :limit

      def initialize(sort, direction_desc, limit)
        @sort = sort
        @direction_desc = direction_desc
        @limit = limit
      end

      def call(sha, access, blobs)
        if sort == SORT_CREATED_AT
          by_created_at(sha, access, blobs)
        else
          by_title(blobs)
        end
      end

      private

      def by_created_at(sha, access, blobs)
        blobs_by_path = blobs.each_with_object({}) do |entry, hash|
          hash[entry.path] = entry
        end

        filenames = access.files_sorted_by_created_at(sha)
        iterator = direction_desc ? filenames.each : filenames.reverse_each

        iterator.with_object([]) do |filename, blobs|
          blob = blobs_by_path[filename]
          next unless blob
          blobs << blob
          break blobs if limit && blobs.size == limit
        end
      end

      def by_title(blobs)
        blobs = blobs.reverse if direction_desc
        blobs = blobs.take(limit) if limit
        blobs
      end
    end
  end
end
