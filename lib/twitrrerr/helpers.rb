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

    # Scans a tweet for screen names.
    # @param screen_name [String] The user's screen name (i.e. that one who clicked "Reply")
    # @param tweet [Twitter::Tweet]
    # @param reply_all [Boolean] Include all users in the reply.
    # @return [Array] An array of user names.
    def users(screen_name, tweet, reply_all = true)
      userlist = [ tweet.user.screen_name ]
      if reply_all
        tweet.text.scan Twitrrerr::SCREEN_NAME_REGEX do |user_name|
          user_name = user_name[0]
          userlist << user_name unless userlist.include?(user_name) or screen_name == user_name
        end
      end
      userlist
    end
  end
end