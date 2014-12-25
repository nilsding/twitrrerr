require 'twitrrerr/helpers'
require 'twitrrerr/add_new_account_dialog'
require 'twitrrerr/compose_widget'
require 'twitrrerr/timeline'
require 'twitrrerr/tweet'
require 'twitrrerr/user_profile'

require 'twitrrerr/ui/main_window'

module Twitrrerr
  # The main window of Twitrrerr.
  class MainWindow < Qt::MainWindow
    include Twitrrerr::Helpers

    slots 'new_account_added(QString, QString, QString)', 'publish_tweet(QString, QString)', 'tweet_added(QWidget*)'
    signals 'new_tweet(QString, QString, QVariant, QString)'
    private_slots 'add_new_account_action()', 'open_user_profile_action()', 'reply_to_tweet(QVariant)', 'retweet(QVariant)', 'favourite(QVariant)', 'close_timeline(QString)'

    attr_accessor :accounts
    attr_reader :timelines

    def initialize(parent = nil)
      super
      @ui = Ui::MainWindow.new
      @ui.setupUi self
      setWindowTitle "Twitrrerr #{Twitrrerr::VERSION}"
      @accounts = {}
      @timelines = {}
      @timelines_view = Qt::HBoxLayout.new @ui.qsa_timelines_content do |obj|
        obj.setObjectName 'timelines_view'
        obj.setSizeConstraint Qt::Layout::SetNoConstraint
        obj.setContentsMargins 0, 0, 0, 0
      end

      connect_actions

      begin
        load_accounts
      rescue Twitter::Error::TooManyRequests => e
        puts "rate limit hit, reset: #{e.rate_limit.reset_at}"
        Qt::MessageBox.critical self, tr("An error occurred"), e.message
        exit 2
      end

      @tray_icon = Qt::SystemTrayIcon.new
      @tray_icon.show

      trap "USR1" do
        puts "Trying to restart streams of all accounts"
        @accounts.each do |k, v|
          puts "Killing thread for #{k}..."
          v[:stream_thread].kill
          puts "Creating new thread for #{k}..."
          init_stream(k)
        end
        puts "Done."
      end unless Gem.win_platform?

      puts 'Enjoy!'
    end

    def new_account_added(screen_name, access_token, access_token_secret)
      Database.db.execute 'INSERT INTO users (screen_name, access_token, access_secret) VALUES (?, ?, ?);',
                          [screen_name, access_token, access_token_secret]
      load_accounts
    end

    def connect_actions
      connect @ui.action_add_new_account, SIGNAL('triggered()'), self, SLOT('add_new_account_action()')
      connect @ui.action_go_to_user, SIGNAL('triggered()'), self, SLOT('open_user_profile_action()')
      connect @ui.compose_widget, SIGNAL('publish_tweet(QString, QString)'), self, SLOT('publish_tweet(QString, QString)')
    end

    def load_accounts
      Database.db.execute 'SELECT screen_name, access_token, access_secret FROM users;' do |row|
        puts "load_accounts: #{row[0]}"
        unless @accounts.include? row[0]
          @accounts[row[0]] = {
              client: new_rest_client(row[1], row[2]),
              streamer: new_streamer(row[1], row[2]),
              stream_thread: nil
          }
          @ui.compose_widget.ui.qcb_account.addItem row[0]
          Qt::execute_in_main_thread(false) do
            open_timelines row[0], true
          end
          init_stream row[0]
        end
      end
    end

    def publish_tweet(screen_name, tweet_text)
      if @ui.compose_widget.retweet
        @accounts[screen_name][:client].retweet @ui.compose_widget.in_reply_to_id
        @ui.compose_widget.retweet = false
      else
        @accounts[screen_name][:client].update! tweet_text, in_reply_to_status_id: @ui.compose_widget.in_reply_to_id
      end
      @ui.compose_widget.ui.qte_tweet.document.clear
      @ui.compose_widget.in_reply_to_id = nil
    rescue Twitter::Error::DuplicateStatus
      Qt::MessageBox.warning self, tr("An error occurred"), tr('Status is a duplicate')
    rescue => e
      Qt::MessageBox.critical self, tr("An error occurred"), e.message
    end

    def open_timelines(screen_name, preload = false)
      %i{home mentions}.each do |type|
        open_timeline(screen_name, type, preload: preload)
      end
    end

    def init_stream(screen_name)
      @accounts[screen_name][:stream_thread] = Thread.new do
        retries = 0
        begin
          @accounts[screen_name][:streamer].user do |object|
            handle_tweet screen_name, object
          end
        rescue => e
          puts "err: #{e.message}"
          puts e.backtrace.join '\n'

          @accounts[screen_name][:stream_thread] = nil

          if retries < Twitrrerr::MAX_RETRIES
            retries += 1
            puts "stream for #{screen_name} died unexpectedly, reconnecting in #{5 * retries} seconds..."
            sleep 5 * retries
            retry
          else
            puts "Too many retries, aborting!"# + "  Kill me with SIGUSR1 to force reconnection of all streams."
          end
        end
      end if @accounts[screen_name][:stream_thread].nil?
    end

    def handle_tweet(screen_name, object)
      case object
        when Twitter::Tweet
          emit new_tweet(screen_name, :home.to_s, object.to_variant, '')
          if object.text.include? "@#{screen_name}"
            emit new_tweet(screen_name, :mentions.to_s, object.to_variant, '')
            @tray_icon.showMessage("New mention!", object.text)
          end
        when Twitter::DirectMessage
          puts "direct message GET"
        when Twitter::Streaming::DeletedTweet
          puts "deleted tweet GET"
        when Twitter::Streaming::Event
          puts "event GET"
        when Twitter::Streaming::FriendList
          puts "friendlist GET"
        when Twitter::Streaming::StallWarning
        else
          puts "warn: unknown object #{object.class.to_s}"
      end
    end

    def tweet_added(tweet_widget)
      connect tweet_widget, SIGNAL('reply_clicked(QVariant)'), self, SLOT('reply_to_tweet(QVariant)')
      connect tweet_widget, SIGNAL('retweet_clicked(QVariant)'), self, SLOT('retweet(QVariant)')
      connect tweet_widget, SIGNAL('favourite_clicked(QVariant)'), self, SLOT('favourite(QVariant)')
    end

    # Opens a new {Twitrrerr::Timeline} for the given user.
    # @param type [Symbol] Timeline type.
    # @param options [Hash] A customizable set of options.
    # @option options [String] :target_screen_name the target user's (i.e. view profile) screen name
    # @option options [Boolean] :preload preload the timeline
    # @option options [Twitter::User] :user_obj User object
    def open_timeline(screen_name, type = :user, options = {})
      options = {
          target_screen_name: nil,
          preload: true,
          user_obj: nil,
          following: nil
      }.merge(options)

      raise ':target_screen_name is nil!' if options[:target_screen_name].nil? and type == :user

      unless options[:target_screen_name].nil? and type == :user
        options[:user_obj] ||= @accounts[screen_name][:client].user options[:target_screen_name]
        options[:following] ||= @accounts[screen_name][:client].friendship?(options[:user_obj], @accounts[screen_name][:client].user)
      end

      timeline_name = :"#{type}_#{screen_name}#{'_' + options[:target_screen_name] if type == :user}"

      @timelines[timeline_name] = Timeline.new(screen_name, type, nil, options)
      connect self, SIGNAL('new_tweet(QString, QString, QVariant, QString)'), @timelines[timeline_name], SLOT('new_tweet(QString, QString, QVariant, QString)')
      connect @timelines[timeline_name], SIGNAL('tweet_added(QWidget*)'), self, SLOT('tweet_added(QWidget*)')
      connect @timelines[timeline_name], SIGNAL('close_clicked(QString)'), self, SLOT('close_timeline(QString)')
      @timelines_view.addWidget @timelines[timeline_name]

      if options[:preload]
        puts "Preloading #{type}_timeline for user #{screen_name}... please wait"
        begin
          if type == :user
            @accounts[screen_name][:client].user_timeline(options[:target_screen_name]).reverse
          else
            @accounts[screen_name][:client].send("#{type}_timeline").reverse
          end.each do |object|
            emit new_tweet(screen_name, type.to_s, object.to_variant, (type == :user ? options[:target_screen_name] : ''))
          end
        rescue => e
          close_timeline timeline_name
          Qt::MessageBox.critical self, tr("An error occurred"), e.message
        end
      end
    end

    private

    :timelines
    :tray_icon

    def add_new_account_action
      dlg = AddNewAccountDialog.new self
      connect dlg, SIGNAL('newUser(QString, QString, QString)'), self, SLOT('new_account_added(QString, QString, QString)')
      dlg.show
    end

    def open_user_profile_action
      user_name = Qt::InputDialog.getText self, tr("Go to user"), tr("Enter an username")
      unless user_name.nil?
        user_name.strip!
        open_timeline @ui.compose_widget.ui.qcb_account.currentText, :user, target_screen_name: user_name
      end
    end

    def reply_to_tweet(tweet)
      tweet = tweet.to_object
      return unless tweet.is_a? Twitter::Tweet

      tweet = tweet.retweeted_tweet if tweet.retweet?

      @ui.compose_widget.in_reply_to_id = tweet.id
      @ui.compose_widget.retweet = false

      users_string = "@#{users(@ui.compose_widget.ui.qcb_account.currentText, tweet).join(" @")} "

      text_cursor = @ui.compose_widget.ui.qte_tweet.textCursor
      current_pos = text_cursor.position
      text_cursor.position = 0
      @ui.compose_widget.ui.qte_tweet.textCursor = text_cursor

      @ui.compose_widget.ui.qte_tweet.insertPlainText users_string

      text_cursor.position = current_pos + users_string.length
      @ui.compose_widget.ui.qte_tweet.textCursor = text_cursor
    end

    def retweet(tweet)
      tweet = tweet.to_object
      return unless tweet.is_a? Twitter::Tweet

      tweet = tweet.retweeted_tweet if tweet.retweet?

      @ui.compose_widget.in_reply_to_id = tweet.id
      @ui.compose_widget.ui.qte_tweet.document.plainText = "RT @#{tweet.user.screen_name}: #{tweet.full_text}"
      @ui.compose_widget.retweet = true
    end

    def favourite(tweet)
      tweet = tweet.to_object
      return unless tweet.is_a? Twitter::Tweet

      tweet = tweet.retweeted_tweet if tweet.retweet?

      @accounts[@ui.compose_widget.ui.qcb_account.currentText][:client].favorite tweet.id
    rescue => e
      Qt::MessageBox.critical self, tr("An error occurred"), e.message
    end

    def close_timeline(timeline_name)
      timeline_name = :"#{timeline_name}" if timeline_name.is_a? String
      @timelines_view.removeWidget @timelines[timeline_name]
      @timelines[timeline_name].dispose
      @timelines.delete timeline_name
    end
  end
end
