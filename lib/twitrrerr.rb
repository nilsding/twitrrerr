require 'Qt'
require 'twitter'
require 'launchy'
require 'fileutils'
require 'httparty'

require 'ext/qvariant'

require 'configuration'
require 'twitrrerr/database'
require 'twitrrerr/main_window'

# Twitrrerr Twitter client.
module Twitrrerr
  # Runs the Qt application.
  def self.run!
    puts <<-END
=============================
 #{' ' * Twitrrerr::VERSION.length}Twitrrerr #{Twitrrerr::VERSION}
 Copyright (c) 2014 nilsding
=============================
END

    create_directory Twitrrerr::CONFIG_PATH
    create_directory Twitrrerr::TEMP_PATH
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

    # Creates a directory if +dir_name+ does not already exist or is a file.
    def self.create_directory(dir_name)
      if File.exists?(dir_name) and !File.directory?(dir_name)
        raise "#{dir_name} already exists and is not a directory!  Aborting."
      elsif !File.exists?(dir_name)
        Dir.mkdir dir_name
      end
    end
end
