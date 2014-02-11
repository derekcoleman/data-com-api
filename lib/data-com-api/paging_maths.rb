require 'active_support/cache'

module DataComApi

  class PagingMaths

    attr_reader :page_size
    attr_reader :max_offset
    attr_reader :total_records

    def initialize(options={})
      options = {
        page_size:     50,
        total_records: 100_000,
        max_offset:    1_000_000  
      }.merge(options)

      @cache         = ActiveSupport::Cache::MemoryStore.new
      @page_size     = options[:page_size]
      @max_offset    = options[:max_offset]
      @total_records = options[:total_records]
    end

    # Fields

    def page_size=(value)
      @page_size = value
      cache.clear
    end

    def max_offset=(value)
      @max_offset = value
      cache.clear
    end

    def total_records=(value)
      @total_records = value
      cache.clear
    end

    # Methods

    def any_record?
      cache.fetch(:any_record?) do
        self.page_size > 0 && self.max_offset > 0 && self.total_records > 0
      end
    end

    def total_pages
      cache.fetch(:total_pages) do
        next 0 unless any_record?

        records_amount = self.total_records
        records_amount = self.max_offset if self.total_records > self.max_offset
        res            = records_amount / self.page_size
        res           += 1 unless (records_amount % self.page_size) == 0

        res
      end
    end

    def page_index(page)
      return nil unless self.any_record?

      page = case page
      when :first then 1
      when :last  then self.total_pages
      else page.to_i
      end

      cache_page = :"page_index_#{ page }"
      return cache.read(cache_page) if cache.exist? cache_page

      case page
      when 0   then raise ArgumentError, "Page index can't be 0"
      when nil then raise ArgumentError, "Page index can't be nil"
      end

      page = nil if page > self.total_pages

      cache.write(cache_page, page)
      page
    end

    def page_from_offset(value)
      return nil unless self.any_record?

      cache_page = :"page_from_offset_#{ value }"
      return cache.read(cache_page) if cache.exist? cache_page

      if value > self.max_offset
        raise ArgumentError, <<-eos
          Offset must not be greater than max_offset (##{ self.max_offset })
        eos
      end

      page  = value / self.page_size
      page += 1 unless (value % self.page_size) == 0
      page  = 1 if value < self.page_size

      cache.write(cache_page, page)
      page
    end

    def offset_from_page(value)
      return nil unless self.any_record?

      cache_page = :"offset_from_page_#{ value }"
      return cache.read(cache_page) if cache.exist? cache_page

      if value > self.max_offset
        raise ArgumentError, "Offset can't be greater than max_offset"
      end
      page = self.page_index(value)

      binding.pry
      # This happens when page > total_pages
      return nil if page.nil?

      records_count = self.total_records
      records_count = self.max_offset if records_count > self.max_offset
      offset = (page - 1) * page_size
      offset = records_count if page == self.total_pages

      cache.write(cache_page, offset)
      offset
    end

    private

      def cache
        @cache
      end

  end

end