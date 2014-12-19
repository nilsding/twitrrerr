require 'twitrrerr/tweet'

require 'twitrrerr/ui/tweet'

module Twitrrerr
  # Tweet widget.
  class Tweet < Qt::Widget

    signals('reply_clicked(QVariant)')
    private_slots('qpb_reply_clicked()')

    attr_reader :ui
    attr_reader :tweet

    # @param tweet [Twitter::Tweet]
    def initialize(tweet, parent = nil)
      super parent
      @ui = Ui::Tweet.new
      @ui.setupUi self

      connect @ui.qpb_reply, SIGNAL('clicked()'), self, SLOT('qpb_reply_clicked()')

      @tweet = tweet
      @ui.ql_screen_name.text = tweet.user.screen_name
      @ui.ql_timestamp.text = tweet.created_at.strftime '%H:%M'
      @ui.ql_tweet_text.text = tweet.full_text
      # TODO: @ui.ql_avatar.pixmap = ... tweet.user.profile_image_uri ...
    end

    private

    def qpb_reply_clicked()
      emit reply_clicked(@tweet.to_variant)
    end

  end
end