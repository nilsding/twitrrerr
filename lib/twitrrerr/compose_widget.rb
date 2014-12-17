require 'uri'

require 'twitrrerr/ui/compose_widget'

module Twitrrerr
  # Compose tweet widget.
  class ComposeWidget < Qt::Widget

    slots 'qpb_send_clicked()', 'qte_tweet_text_changed()'
    signals 'publish_tweet(QString, QString)'

    attr_reader :ui

    def initialize(parent = nil)
      super parent
      @ui = Ui::ComposeWidget.new
      @ui.setupUi self

      connect @ui.qpb_send, SIGNAL('clicked()'), self, SLOT('qpb_send_clicked()')
      connect @ui.qte_tweet, SIGNAL('textChanged()'), self, SLOT('qte_tweet_text_changed()')
    end

    # Emits publish_tweet(screen_name, tweet_text)
    def qpb_send_clicked
      emit publish_tweet(@ui.qcb_account.currentText, @ui.qte_tweet.document.toPlainText)
    end

    def qte_tweet_text_changed
      tweet_text = @ui.qte_tweet.document.toPlainText
      @ui.ql_chars.text = 140 - get_real_length(tweet_text)
    end

    # @param tweet_text [String]
    def get_real_length(tweet_text)
      length = tweet_text.length
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