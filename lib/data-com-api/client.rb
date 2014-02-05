require 'data-com-api/errors'

module DataComApi

  class Client

    ENV_NAME_TOKEN = 'DATA_COM_TOKEN'.freeze
    TIME_ZONE      = 'Pacific Time (US & Canada)'.freeze

    def initialize(api_token=nil)
      @token     = api_token || ENV[ENV_NAME_TOKEN]
      @page_size = 50

      raise TokenFailError, 'No token set!' unless @token
    end

    def page_size
      @page_size
    end

    # Page size = 0 returns objects count only (small request)
    def page_size=(value)
      real_value = value.to_i

      if real_value < 0 || real_value > 100
        raise ParamError, "page_size must be between 0 and 100, received #{ real_value }"
      end

      @page_size = real_value
    end

    private

      def token
        @token
      end

  end

end