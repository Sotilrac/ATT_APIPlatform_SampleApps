#!/usr/bin/ruby

# Licensed by AT&T under 'Software Development Kit Tools Agreement.' 2013
# TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION: http://developer.att.com/sdk_agreement/
# Copyright 2013 AT&T Intellectual Property. All rights reserved. http://developer.att.com
# For more information contact developer.support@att.com

require 'rubygems'
require 'json'
require 'rest_client'
require 'sinatra'
require 'open-uri'
require 'sinatra/config_file'
require File.join(File.dirname(__FILE__), 'common.rb')

enable :sessions

config_file 'config.yml'

set :port, settings.port
set :protection, :except => :frame_options

SCOPE = 'ADS'
RestClient.proxy = settings.proxy

['/getAds'].each do |path|
  before path do
    obtain_tokens(settings.FQDN, settings.api_key, settings.secret_key, SCOPE, settings.tokens_file)
  end
end

get '/' do
  erb :ads
end

post '/getAds' do
  get_ads
end

def get_ads
  invalidParams = Array.new 

  if params[:category]
    url = "#{settings.FQDN}/rest/1/ads?Category=#{params[:category]}"
  else
    invalidParams << "Category" 
  end

  if invalidParams.any?
    @error = "Invalid parameters: " + invalidParams.join(", ")
  else
    response = RestClient.get(url, :Authorization => "BEARER #{@access_token}", :User_Agent => "#{@env["HTTP_USER_AGENT"]}", :UDID => "012266005922565000000000000000", :Content_Type => 'application/json', :Accept => 'application/json') 

      case response.code
      when 204
        @error = 'No Ads were returned'
      when 200,201
        @result = JSON.parse(response)["AdsResponse"]["Ads"]
      else
        @error = response
      end
  end

rescue => e
  @error = e.message
ensure
  return erb :ads
end
