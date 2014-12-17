require 'twitrrerr/ui/timeline'

module Twitrrerr
  # Timeline widget.
  class Timeline < Qt::Widget

    slots 'new_tweet(QVariant)'

    attr_reader :ui
    attr_reader :tweets_view

    def initialize(timeline_name, parent = nil)
      super parent
      @ui = Ui::Timeline.new
      @ui.setupUi self
      @ui.ql_timeline_name.text = timeline_name
      @tweets = {}
      @tweets_view = Qt::VBoxLayout.new @ui.qsa_tweets_content do |obj|
        obj.setObjectName 'tweets_view'
        obj.setSizeConstraint Qt::Layout::SetNoConstraint
        obj.setContentsMargins 0, 0, 0, 0
      end
    end

    def new_tweet(tweet)
      tweet = tweet.to_object
      @tweets[:"#{tweet.id}"] = tweet
      @tweets_view.insertWidget 0, Twitrrerr::Tweet.new(tweet)
    end
  end
end