module Twitrrerr
  # Twitrrerr version number
  VERSION = '0.0.1'

  # Path to the configuration directory
  CONFIG_PATH = File.expand_path('./.twitrrerr', Dir.home)

  # OAuth consumer keys
  OAUTH_KEYS = {
      consumer_key: 'SNbZ3xndTrT5DLxf1N29Ujne1',
      consumer_secret: 'n1VHxFbP3F4UlLmu81RbpaKf4iRtpwEV5Efb3FOWUgrneO8unQ'
  }

  # Length of shortened urls
  SHORTENED_URL_LENGTH = 22

  # Regular expression to match Twitter screen names
  SCREEN_NAME_REGEX = /@([A-Za-z0-9_]{1,15})/
end