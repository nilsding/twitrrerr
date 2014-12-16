require 'twitter'

module Twitrrerr
  # This module contains some helper methods.
  module Helpers

    # Creates a new Twitter::REST::Client object with the user's access tokens.
    # @param access_token [String] the user's access token
    # @param access_secret [String] the user's access secret
    # @return [Twitter::REST::Client] a new Twitter REST client object for this user
    def new_rest_client(access_token, access_secret)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = Twitrrerr::OAUTH_KEYS[:consumer_key]
        config.consumer_secret     = Twitrrerr::OAUTH_KEYS[:consumer_secret]
        config.access_token        = access_token
        config.access_token_secret = access_secret
      end
    end

    # Creates a new Twitter::Streaming::Client object with the user's access tokens.
    # @param access_token [String] the user's access token
    # @param access_secret [String] the user's access secret
    # @return [Twitter::Streaming::Client] a new Twitter REST client object for this user
    def new_streamer(access_token, access_secret)
      Twitter::Streaming::Client.new do |config|
        config.consumer_key        = Twitrrerr::OAUTH_KEYS[:consumer_key]
        config.consumer_secret     = Twitrrerr::OAUTH_KEYS[:consumer_secret]
        config.access_token        = access_token
        config.access_token_secret = access_secret
      end
    end
  end
end