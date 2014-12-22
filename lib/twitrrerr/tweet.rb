require 'twitrrerr/tweet'

require 'twitrrerr/ui/tweet'

module Twitrrerr
  # Tweet widget.
  class Tweet < Qt::Widget

    signals 'reply_clicked(QVariant)', 'retweet_clicked(QVariant)', 'favourite_clicked(QVariant)', 'avatar_loaded(QString)'
    private_slots 'qpb_reply_clicked()', 'qpb_retweet_clicked()', 'qpb_favourite_clicked()', 'avatar_loaded(QString)'

    attr_reader :ui
    attr_reader :tweet

    # @param tweet [Twitter::Tweet]
    def initialize(tweet, parent = nil)
      super parent
      @ui = Ui::Tweet.new
      @ui.setupUi self

      connect @ui.qpb_reply, SIGNAL('clicked()'), self, SLOT('qpb_reply_clicked()')
      connect @ui.qpb_retweet, SIGNAL('clicked()'), self, SLOT('qpb_retweet_clicked()')
      connect @ui.qpb_favourite, SIGNAL('clicked()'), self, SLOT('qpb_favourite_clicked()')
      connect self, SIGNAL('avatar_loaded(QString)'), self, SLOT('avatar_loaded(QString)')

      @tweet = tweet
      @ui.ql_screen_name.text = tweet.user.screen_name
      @ui.ql_timestamp.text = tweet.created_at.strftime '%H:%M'
      @ui.ql_tweet_text.text = tweet.full_text
      @ui.ql_followers_count.text = hhh tweet.user.followers_count
      @ui.ql_friends_count.text = hhh tweet.user.friends_count
      load_and_show_avatar
    end

    private

    @@mutex ||= Mutex.new

    def qpb_reply_clicked()
      emit reply_clicked(@tweet.to_variant)
    end

    def qpb_retweet_clicked()
      emit retweet_clicked(@tweet.to_variant)
    end

    def qpb_favourite_clicked()
      emit favourite_clicked(@tweet.to_variant)
    end

    def avatar_loaded(file_name)
      Qt::execute_in_main_thread(false) do
        pixmap = Qt::Pixmap.new file_name
        @ui.ql_avatar.pixmap = pixmap
      end
    end

    def load_and_show_avatar
      Thread.new do
        file_name = get_temp_avatar_file_name
        @@mutex.synchronize do
          unless File.exists? file_name
            response = HTTParty.get @tweet.user.profile_image_uri
            File.open file_name, 'w' do |f|
              f.write response.body
            end
          end
          emit avatar_loaded(file_name)
        end
      end
    end

    def get_temp_avatar_file_name
      x = @tweet.user.profile_image_uri.to_s.split('/')
      File.expand_path "#{x[-2]}_#{x[-1]}", Twitrrerr::TEMP_PATH
    end

    def hhh(number)
      # TODO: give this method a different name… and probably rewrite it too.
      case number
      when (1_000...1_000_000)
        "#{(number / 1_000.0).round 1}K"
      when (1_000_000...1_000_000_000)
        "#{(number / 1_000_000.0).round 1}M"
      else
        "#{number}"
      end
    end
  end
end