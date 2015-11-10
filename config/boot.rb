require 'bundler'
Bundler.setup

require 'dotenv'
Dotenv.load

require 'platform-api'
$heroku = PlatformAPI.connect_oauth(ENV['HEROKU_API_TOKEN'])

require 'sinatra/base'
require 'sinatra/flash'
require 'active_support/time_with_zone'
require 'active_support/core_ext/time'
require 'eventmachine'
require 'em-http'

Time.zone = 'CET'

require './app'
