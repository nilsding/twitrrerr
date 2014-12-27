require 'uri'

require 'twitrrerr/ui/compose_widget'

module Twitrrerr
  # Compose tweet widget.
  class ComposeWidget < Qt::Widget

    signals 'publish_tweet(QString, QString)'
    private_slots 'qpb_send_clicked()', 'qte_tweet_text_changed()'

    attr_reader :ui
    attr_accessor :in_reply_to_id
    attr_accessor :retweet

    def initialize(parent = nil)
      super parent
      @ui = Ui::ComposeWidget.new
      @ui.setupUi self
      @ui.ql_in_reply_to_tweet_text.visible = false

      @in_reply_to_id = nil
      @retweet = false

      connect @ui.qpb_send, SIGNAL('clicked()'), self, SLOT('qpb_send_clicked()')
      connect @ui.qte_tweet, SIGNAL('textChanged()'), self, SLOT('qte_tweet_text_changed()')
    end

    # Emits publish_tweet(screen_name, tweet_text)
    def qpb_send_clicked
      if @ui.ql_chars.text != "140"
        emit publish_tweet(@ui.qcb_account.currentText, @ui.qte_tweet.document.toPlainText)
      else
        Qt::MessageBox.warning self, tr("Warning"), tr("Tweet can not be empty")
      end
    end

    def qte_tweet_text_changed
      tweet_text = @ui.qte_tweet.document.toPlainText
      @ui.ql_chars.text = 140 - get_real_length(tweet_text)
      @retweet = false if @retweet
    end

    # @param tweet_text [String]
    def get_real_length(tweet_text)
      length = tweet_text.strip.length
      URI.extract(tweet_text, ['http', 'https']) do |url|
        if url.length >= Twitrrerr::SHORTENED_URL_LENGTH
          length -= url.length - SHORTENED_URL_LENGTH
        else
          length += Twitrrerr::SHORTENED_URL_LENGTH - url.length
        end
      end
      length
    end
  end
end