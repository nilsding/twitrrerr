require 'twitrrerr/ui/addnewaccountdialog'
require 'oauth'

module Twitrrerr
  # OAuth pin auth dialog.
  class AddNewAccountDialog < Qt::Dialog
    slots 'accept()', 'reject()'
    signals 'newUser(QString, QString, QString)'

    def initialize(parent = nil)
      super parent
      @ui = Ui::AddNewAccountDialog.new
      @ui.setupUi self
      get_request_token
    end

    def get_request_token
      url = request_token_url
      puts "opening #{url}"
      Launchy.open url
    rescue => e
      Qt::MessageBox.critical self, tr("An error occurred"), e.message
    end

    def accept
      return unless @request_token
      pin = @ui.qle_pin.text.strip
      if pin =~ /^\d+$/
        access_token = @request_token.get_access_token(oauth_verifier: pin)
        oauth_response = access_token.get('/1.1/account/verify_credentials.json?skip_status=true')
        screen_name = oauth_response.body.match(/"screen_name"\s*:\s*"(.*?)"/).captures.first
        emit newUser(screen_name, access_token.token, access_token.secret)
        super
      else
        Qt::MessageBox.warning self, "Twitrrerr", tr('Please enter a valid PIN!')
      end
    end

    def reject
      super
    end

    private

      def request_token_url(callback = OAuth::OUT_OF_BAND)
        consumer = OAuth::Consumer.new Twitrrerr::OAUTH_KEYS[:consumer_key],
                                       Twitrrerr::OAUTH_KEYS[:consumer_secret],
                                       site: Twitter::REST::Client::BASE_URL,
                                       scheme: :header
        @request_token = consumer.get_request_token(oauth_callback: callback)
        @request_token.authorize_url(oauth_callback: callback)
      end
  end
end