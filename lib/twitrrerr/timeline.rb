require 'twitrrerr/ui/timeline'

module Twitrrerr
  # Timeline widget.
  class Timeline < Qt::Widget

    slots 'new_tweet(QString, QVariant, QVariant)'

    attr_reader :ui
    attr_reader :tweets_view

    # @param user_name [String] the target user's (i.e. view profile) screen name
    def initialize(timeline_type, screen_name, parent = nil, user_name = '-- unknown --')
      super parent
      @ui = Ui::Timeline.new
      @ui.setupUi self
      @ui.ql_timeline_name.text = "#{get_timeline_name(timeline_type, user_name)} (#{screen_name})"
      @tweets = {}
      @tweets_view = Qt::VBoxLayout.new @ui.qsa_tweets_content do |obj|
        obj.setObjectName 'tweets_view'
        obj.setSizeConstraint Qt::Layout::SetMinimumSize
        obj.setContentsMargins 0, 0, 0, 0
      end
      @timeline_type = timeline_type
      @screen_name = screen_name
    end

    def new_tweet(screen_name, timeline_type, tweet)
      return if screen_name != @screen_name or timeline_type.to_object != @timeline_type
      tweet = tweet.to_object
      return unless tweet.is_a? Twitter::Tweet
      @tweets[:"#{tweet.id}"] = tweet
      @tweets_view.insertWidget 0, Twitrrerr::Tweet.new(tweet)
    end

    private

      def get_timeline_name(timeline_type, user_name = '')
        case timeline_type
        when :home
          tr('Home timeline')
        when :user
          user_name
        else
          tr('Unknown timeline')
        end
      end
  end
end