require 'twitrrerr/ui/compose_widget'

module Twitrrerr
  # Compose tweet widget.
  class ComposeWidget < Qt::Widget

    slots 'qpb_send_clicked()'
    signals 'publish_tweet(QString, QString)'

    attr_reader :ui

    def initialize(parent = nil)
      super parent
      @ui = Ui::ComposeWidget.new
      @ui.setupUi self

      connect @ui.qpb_send, SIGNAL('clicked()'), self, SLOT('qpb_send_clicked()')
    end

    # Emits publish_tweet(screen_name, tweet_text)
    def qpb_send_clicked
      emit publish_tweet(@ui.qcb_account.currentText, @ui.qte_tweet.document.toPlainText)
    end
  end
end