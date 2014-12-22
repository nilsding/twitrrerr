require 'twitrrerr/ui/user_profile'

# UserProfile widget.
class UserProfile < Qt::Widget

  signals 'avatar_loaded(QString)'
  private_slots 'avatar_loaded(QString)'

  attr_reader :ui
  attr_reader :user
  attr_reader :following

  # @param user [Twitter::User]
  def initialize(user, following = false, parent = nil)
    super parent
    @ui = Ui::UserProfile.new
    @ui.setupUi self

    connect self, SIGNAL('avatar_loaded(QString)'), self, SLOT('avatar_loaded(QString)')

    @user = user
    @following = following
    @ui.ql_display_name.text = user.name
    @ui.ql_screen_name.text = "@#{user.screen_name}"
    @ui.ql_followers_count.text = user.followers_count
    @ui.ql_friends_count.text = user.friends_count
    @ui.ql_tweets_count.text = user.statuses_count
    @ui.ql_bio.text = user.description
    @ui.ql_follows_you.hide unless following
    load_and_show_avatar
  end

  private

  @@mutex ||= Mutex.new

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
          response = HTTParty.get @user.profile_image_uri
          File.open file_name, 'wb' do |f|
            f.write response.body
          end
        end
        emit avatar_loaded(file_name)
      end
    end
  end

  def get_temp_avatar_file_name
    x = @user.profile_image_uri.to_s.split('/')
    File.expand_path "#{x[-2]}_#{x[-1]}", Twitrrerr::TEMP_PATH
  end
end