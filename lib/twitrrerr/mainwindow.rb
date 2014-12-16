require 'twitrrerr/helpers'
require 'twitrrerr/addnewaccountdialog'

module Twitrrerr
  # The main window of Twitrrerr.
  class MainWindow < Qt::MainWindow
    include Twitrrerr::Helpers

    slots 'add_new_account_action()', 'new_account_added(QString, QString, QString)'

    attr_accessor :accounts

    def initialize(parent = nil)
      super
      setWindowTitle "Twitrrerr #{Twitrrerr::VERSION}"
      @accounts = {}
      create_actions
      create_menus
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

    def create_actions
      @action_add_new_account = Qt::Action.new tr('Add &new account...'), self
      connect @action_add_new_account, SIGNAL('triggered()'), self, SLOT('add_new_account_action()')
    end

    def load_accounts
      Database.db.execute 'SELECT screen_name, access_token, access_secret FROM users LIMIT 1;' do |row|
        @accounts[row[0]] = {
            client: new_rest_client(row[1], row[2]),
            streamer: new_streamer(row[1], row[2])
        } unless @accounts.include? row[0]
      end
    end

    def create_menus
      @menu_accounts = menuBar().addMenu(tr('&Accounts'))
      @menu_accounts.addAction @action_add_new_account
    end
  end
end
