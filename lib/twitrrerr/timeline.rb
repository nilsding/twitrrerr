require 'twitrrerr/ui/timeline'

module Twitrrerr
  # Timeline widget.
  class Timeline < Qt::Widget

    slots 'new_tweet(QString, QString, QVariant, QString)'
    signals 'tweet_added(QWidget*)', 'close_clicked(QString)'
    private_slots 'qpb_close_clicked()'

    attr_reader :ui
    attr_reader :tweets_view

    # @param options [Hash] A customizable set of options.
    # @option options [String] :target_screen_name the target user's (i.e. view profile) screen name
    # @option options [Twitter::User] :user_obj User object
    def initialize(screen_name, timeline_type, parent = nil, options = {})
      @options = {
          target_screen_name: '',
          user_obj: nil
      }.merge(options)
      super parent
      @ui = Ui::Timeline.new
      @ui.setupUi self

      connect @ui.qpb_close, SIGNAL('clicked()'), self, SLOT('qpb_close_clicked()')

      @ui.ql_timeline_name.text = "#{get_timeline_name(timeline_type, @options[:target_screen_name])} (#{screen_name})"
      @tweets = {}
      @tweets_view = Qt::VBoxLayout.new @ui.qsa_tweets_content do |obj|
        obj.setObjectName 'tweets_view'
        obj.setSizeConstraint Qt::Layout::SetMinimumSize
        obj.setContentsMargins 0, 0, 0, 0
      end
      @timeline_type = timeline_type
      @screen_name = screen_name

      @user = options[:user_obj]
      if timeline_type == :user and !@user.nil?
        @user_widget = UserProfile.new(@user, options[:following])
        @tweets_view.insertWidget 0, @user_widget
      end
    end

    def new_tweet(screen_name, timeline_type, tweet, user_name)
      return if screen_name != @screen_name or timeline_type.to_sym != @timeline_type
      return if @timeline_type == :user and user_name != @options[:target_screen_name]

      tweet = tweet.to_object
      return unless tweet.is_a? Twitter::Tweet
      @tweets[:"#{tweet.id}"] = tweet

      tweet_widget = Twitrrerr::Tweet.new(tweet)
      insert_point = @timeline_type == :user ? 1 : 0
      @tweets_view.insertWidget insert_point, tweet_widget

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

    def qpb_close_clicked
      emit close_clicked("#{@timeline_type}_#{@screen_name}#{'_' + @user.screen_name if @timeline_type == :user}")
    end
  end
end
