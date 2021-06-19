require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::SteamCheckServerPerIpAgent do
  before(:each) do
    @valid_options = Agents::SteamCheckServerPerIpAgent.new.default_options
    @checker = Agents::SteamCheckServerPerIpAgent.new(:name => "SteamCheckServerPerIpAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
