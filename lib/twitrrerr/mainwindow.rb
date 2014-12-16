require 'twitrrerr/addnewaccountdialog'

module Twitrrerr
  class MainWindow < Qt::MainWindow
    slots 'add_new_account_action()', 'new_account_added(QString, QString, QString)'

    def initialize(parent = nil)
      super
      setWindowTitle "Twitrrerr #{Twitrrerr::VERSION}"
      create_actions
      create_menus
      load_accounts
    end

    def new_account_added(screen_name, access_token, access_token_secret)
      Database.db.execute 'INSERT INTO users (screen_name, access_token, access_secret) VALUES (?, ?, ?);',
                          [screen_name, access_token, access_token_secret]
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
      Database.db.execute 'SELECT screen_name, access_token, access_secret FROM users;' do |row|
        # TODO
      end
    end

    def create_menus
      @menu_accounts = menuBar().addMenu(tr('&Accounts'))
      @menu_accounts.addAction @action_add_new_account
    end
  end
end
