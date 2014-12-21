require 'twitrrerr/ui/timeline'

module Twitrrerr
  # Timeline widget.
  class Timeline < Qt::Widget

    slots 'new_tweet(QString, QString, QVariant, QString)'
    signals 'tweet_added(QWidget*)'

    attr_reader :ui
    attr_reader :tweets_view

    # @param options [Hash] A customizable set of options.
    # @option options [String] :target_screen_name the target user's (i.e. view profile) screen name
    def initialize(screen_name, timeline_type, parent = nil, options = {})
      @options = {
          target_screen_name: ''
      }.merge(options)
      super parent
      @ui = Ui::Timeline.new
      @ui.setupUi self
      @ui.ql_timeline_name.text = "#{get_timeline_name(timeline_type, @options[:target_screen_name])} (#{screen_name})"
      @tweets = {}
      @tweets_view = Qt::VBoxLayout.new @ui.qsa_tweets_content do |obj|
        obj.setObjectName 'tweets_view'
        obj.setSizeConstraint Qt::Layout::SetMinimumSize
        obj.setContentsMargins 0, 0, 0, 0
      end
      @timeline_type = timeline_type
      @screen_name = screen_name
    end

    def new_tweet(screen_name, timeline_type, tweet, user_name)
      return if screen_name != @screen_name or timeline_type.to_sym != @timeline_type
      return if @timeline_type == :user and user_name != @options[:target_screen_name]

      tweet = tweet.to_object
      return unless tweet.is_a? Twitter::Tweet
      @tweets[:"#{tweet.id}"] = tweet

      tweet_widget = Twitrrerr::Tweet.new(tweet)
      @tweets_view.insertWidget 0, tweet_widget

      emit tweet_added(tweet_widget)
    end

    private

      def get_timeline_name(timeline_type, user_name = '')
        case timeline_type
        when :home
          tr('Home timeline')
        when :mentions
          tr('Mentions')
        when :user
          tr('User: ') + user_name
        else
          tr('Unknown timeline')
        end
      end
  end
end
