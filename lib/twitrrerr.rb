require 'Qt'
require 'twitter'
require 'launchy'

require 'configuration'
require 'twitrrerr/database'
require 'twitrrerr/mainwindow'

# Twitrrerr Twitter client.
module Twitrrerr
  # Runs the Qt application.
  def self.run!
    create_config_dir
    Database.init

    app = Qt::Application.new ARGV

    Qt::Application.setOrganizationName 'nilsding'
    Qt::Application.setOrganizationDomain 'nilsding.org'
    Qt::Application.setApplicationName 'Twitrrerr'

    main_window = MainWindow.new
    main_window.show
    app.exec
  end

  private

    # Creates the config directory.
    def self.create_config_dir
      if File.exists?(Twitrrerr::CONFIG_PATH) and !File.directory?(Twitrrerr::CONFIG_PATH)
        raise "#{Twitrrerr::CONFIG_PATH} already exists and is not a directory!  Aborting."
      elsif !File.exists?(Twitrrerr::CONFIG_PATH)
        Dir.mkdir Twitrrerr::CONFIG_PATH
      end
    end
end
