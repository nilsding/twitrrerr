require 'twitrrerr/helpers'
require 'twitrrerr/add_new_account_dialog'
require 'twitrrerr/compose_widget'
require 'twitrrerr/timeline'
require 'twitrrerr/tweet'

require 'twitrrerr/ui/main_window'

module Twitrrerr
  # The main window of Twitrrerr.
  class MainWindow < Qt::MainWindow
    include Twitrrerr::Helpers

    slots 'new_account_added(QString, QString, QString)', 'publish_tweet(QString, QString)'
    signals 'new_tweet(QString, QVariant, QVariant)'
    private_slots 'add_new_account_action()'

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
      load_accounts
    end

    def new_account_added(screen_name, access_token, access_token_secret)
      Database.db.execute 'INSERT INTO users (screen_name, access_token, access_secret) VALUES (?, ?, ?);',
                          [screen_name, access_token, access_token_secret]
      load_accounts
    end

    def add_new_account_action
      dlg = AddNewAccountDialog.new self
      connect dlg, SIGNAL('newUser(QString, QString, QString)'), self, SLOT('new_account_added(QString, QString, QString)')
      dlg.show
    end

    def connect_actions
      connect @ui.action_add_new_account, SIGNAL('triggered()'), self, SLOT('add_new_account_action()')
      connect @ui.compose_widget, SIGNAL('publish_tweet(QString, QString)'), self, SLOT('publish_tweet(QString, QString)')
    end

    private

    :timelines

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
          open_timelines row[0], true
          init_stream row[0]
        end
      end
    end

    def publish_tweet(screen_name, tweet_text)
      @accounts[screen_name][:client].update tweet_text
      @ui.compose_widget.ui.qte_tweet.text = ''
    rescue => e
      Qt::MessageBox.critical self, tr("An error occurred"), e.message
    end

    def open_timelines(screen_name, preload = false)
      @timelines[:"home_#{screen_name}"] = Timeline.new(:home, screen_name)
      connect self, SIGNAL('new_tweet(QString, QVariant, QVariant)'), @timelines[:"home_#{screen_name}"], SLOT('new_tweet(QString, QVariant, QVariant)')
      @timelines_view.addWidget @timelines[:"home_#{screen_name}"]

      if preload
        puts "Preloading tweets for user #{screen_name}... please wait"
        @accounts[screen_name][:client].home_timeline.each do |object|
          emit new_tweet(screen_name, :home.to_variant, object.to_variant)
        end
      end
    end

    def init_stream(screen_name)
      @accounts[screen_name][:stream_thread] = Thread.new do
        begin
          @accounts[screen_name][:streamer].user do |object|
            handle_tweet screen_name, object
          end
        rescue => e
          puts "err: #{e.message}"
          @accounts[screen_name][:stream_thread] = nil
        end
      end if @accounts[screen_name][:stream_thread].nil?
    end

    def handle_tweet(screen_name, object)
      case object
        when Twitter::Tweet
          puts "tweet GET"
          emit new_tweet(screen_name, :home.to_variant, object.to_variant)
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
  end
end
