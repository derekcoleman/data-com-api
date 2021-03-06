require 'data-com-api/responses/base'

module DataComApi
  module Responses
    # Abstract class
    class SearchBase < Base

      
      def initialize(api_client, received_options)
        @options = received_options
        super(api_client)

        # Cache pagesize, MUST NOT change between requests
        @page_size = client.page_size
      end

      def size
        return @size if @size

        size_options = options.merge(
          offset:    0,
          page_size: client.size_only_page_size
        )
        
        calculate_size_from_request! self.perform_request(size_options)
      end

      def max_size
        self.real_max_offset + page_size
      end

      def real_size
        self.size > self.real_max_offset ? self.max_size : self.size
      end

      def at_offset(offset)
        page_options = options.merge(
          offset:    offset,
          page_size: page_size
        )

        request = self.perform_request(page_options)
        calculate_size_from_request! request

        self.transform_request request
      end

      # Be careful, this will load all records in memory, check total_records
      # before doing such a thing
      def all
        all_records = Array.new(self.real_size)

        self.each_with_index { |record, index| all_records[index] = record }

        all_records
      end

      def each_with_index
        total_records             = 0
        records_per_previous_page = page_size
        current_offset            = 0

        loop do
          break if current_offset > self.real_max_offset

          records = at_offset(current_offset)

          records.each_with_index do |record, index|
            yield(record, index + current_offset)
          end

          records_per_previous_page  = records.size
          current_offset            += page_size
          total_records             += records_per_previous_page

          if records_per_previous_page != page_size || total_records == self.size
            break
          end
        end
      end

      def real_max_offset
        return @real_max_offset if @real_max_offset

        @real_max_offset = client.max_offset
        @real_max_offset = @real_max_offset - (@real_max_offset % page_size)
      end

      alias_method :to_a, :all
      alias_method :each, :each_with_index

      protected

        def page_size
          @page_size
        end

        def options
          @options
        end

      private

        def calculate_size_from_request!(request)
          return if @size

          @size = request['totalHits'].to_i
        end

    end
  end
end