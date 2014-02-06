require 'httparty'
require 'json'
require 'data-com-api/errors'
require 'data-com-api/responses/search_contact.rb'

module DataComApi

  class Client
    include HTTParty
    base_uri 'https://www.jigsaw.com'

    ENV_NAME_TOKEN = 'DATA_COM_TOKEN'.freeze
    TIME_ZONE      = 'Pacific Time (US & Canada)'.freeze
    BASE_OFFSET    = 0

    attr_reader :api_calls_count
    attr_reader :token

    def initialize(api_token=nil)
      @token           = api_token || ENV[ENV_NAME_TOKEN]
      @page_size       = 50
      @api_calls_count = 0

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

    def search_contact(options={})
      Responses::SearchContact.new(self, options)
    end

    # Raw calls

    def company_contact_count_raw(company_id, include_graveyard)
      params = QueryParameters.new(
        token:             token,
        company_id:        company_id,
        include_graveyard: include_graveyard
      )

      response = self.class.get(
        "/rest/companyContactCount/#{ params.company_id }.json",
        params
      )
      increase_api_calls_count!

      response.body
    end

    def search_contact_raw(options={})
      response = self.class.get(
        "/rest/searchContact.json",
        generate_params(options)
      )
      increase_api_calls_count!

      response.body
    end

    def search_company_raw(options={})
      response = self.class.get(
        "/rest/searchCompany.json",
        generate_params(options)
      )
      increase_api_calls_count!

      response.body
    end

    def contacts_raw(contact_ids, username, password, purchase_flag=false)
      raise ParamError, 'One contact required at least' unless contact_ids.size > 0

      params = QueryParameters.new(
        token:         token,
        username:      username,
        password:      password,
        purchase_flag: purchase_flag
      )
      
      response = self.class.get(
        "/rest/contacts/#{ contact_ids.join(',') }.json",
        params
      )
      increase_api_calls_count!

      response.body
    end

    def partner_contacts_raw(contact_ids, end_org_id, end_user_id)
      raise ParamError, 'One contact required at least' unless contact_ids.size > 0

      params = QueryParameters.new(
        token:       token,
        end_org_id:  end_org_id,
        end_user_id: end_user_id
      )
      
      response = self.class.get(
        "/rest/partnerContacts/#{ contact_ids.join(',') }.json",
        params
      )
      increase_api_calls_count!

      response.body
    end

    def partner_raw
      params = QueryParameters.new(token: token)
      
      response = self.class.get(
        "/rest/partner.json",
        params
      )
      increase_api_calls_count!

      response.body
    end

    def user_raw(username, password)
      params = QueryParameters.new(
        username: username,
        password: password,
        token:    token
      )
      
      response = self.class.get(
        "/rest/user.json",
        params
      )
      increase_api_calls_count!

      response.body
    end

    # JSON calls

    def company_contact_count_raw_json(company_id, include_graveyard)
      json_or_raise company_contact_count_raw(company_id, include_graveyard)
    end

    def search_contact_raw_json(options={})
      json_or_raise search_contact_raw(options)
    end

    def search_company_raw_json(options={})
      json_or_raise search_company_raw(options)
    end

    def contacts_raw_json(contact_ids, username, password, purchase_flag=false)
      json_or_raise contacts_raw(
        contact_ids,
        username,
        password,
        purchase_flag
      )
    end

    def partner_contacts_raw_json(contact_ids, end_org_id, end_user_id)
      json_or_raise partner_contacts_raw(
        contact_ids,
        end_org_id,
        end_user_id
      )
    end

    def partner_raw_json
      json_or_raise partner_raw
    end

    def user_raw_json(username, password)
      json_or_raise user_raw(username, password)
    end

    private

      def json_or_raise(json_str)
        json = JSON.parse(json_str)

        if json.kind_of? Array
          error = json.first
          raise Error.from_code(error['errorCode']).new(error['errorMsg'])
        end

        json
      end

      def generate_params(options)
        params           = QueryParameters.new(options)
        params.offset    = BASE_OFFSET unless params.offset
        params.page_size = page_size   unless params.pageSize
        params.token     = token

        params
      end

      def increase_api_calls_count!
        @api_calls_count += 1
      end

  end

end