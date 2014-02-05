require 'spec_helper'
require 'data-com-api/client'

describe DataComApi::Client do

  subject(:client) { FactoryGirl.build(:client) }

  it "has a valid factory" do
    expect{client}.not_to raise_error
  end

  context "env #{ described_class::ENV_NAME_TOKEN } empty" do
    before do
      @env_data_com_token                  = ENV[described_class::ENV_NAME_TOKEN]
      ENV[described_class::ENV_NAME_TOKEN] = nil
    end

    after do
      ENV[described_class::ENV_NAME_TOKEN] = @env_data_com_token
    end

    it ".new raises error when both no token passed and no env DATA_COM_TOKEN set" do
      expect{described_class.new}.to raise_error
    end

  end

  it "#page_size= accepts values between 0 and 100" do
    expect{client.page_size = Random.rand(101)}.not_to raise_error
  end

  it "#page_size= doesn't accept values > 100" do
    expect{client.page_size = 101}.to raise_error DataComApi::ParamError
  end

  it "#page_size= doesn't accept values < 0" do
    expect{client.page_size = (-1)}.to raise_error DataComApi::ParamError
  end

  it "#search_contact without params returns size > 0" do
    expect{client.search_contact.size}.to > 0
  end

  # it "#company_contact_count" do
  #   contacts = client.company_contact_count('existing_company_id')

  #   contacts
  # end

end
