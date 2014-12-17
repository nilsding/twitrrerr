require 'twitrrerr/tweet'

require 'twitrrerr/ui/tweet'

module Twitrrerr
  # Tweet widget.
  class Tweet < Qt::Widget

    attr_reader :ui
    attr_reader :tweet

    # @param tweet [Twitter::Tweet]
    def initialize(tweet, parent = nil)
      super parent
      @ui = Ui::Tweet.new
      @ui.setupUi self
      @tweet = tweet
      @ui.ql_screen_name.text = tweet.user.screen_name
      @ui.ql_timestamp.text = tweet.created_at.strftime '%H:%m'
      @ui.ql_tweet_text.text = tweet.text
    end
  end
end