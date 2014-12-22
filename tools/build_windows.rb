#!/usr/bin/env ruby

Dir.chdir File.expand_path('../..', __FILE__)

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'configuration'

DIST_PATH = './Output'
SCRIPT_FILE = './bin/twitrrerr'
ADDITIONAL_FILES = %w(LICENSE README.md)
ISS_FILE = './twitrrerr.iss'
OUT_FILE_NAME = "#{DIST_PATH}/twitrrerr.exe"
SETUP_FILE_NAME = "install-twitrrerr-#{Twitrrerr::VERSION}"
OCRA_OPTIONS = '--add-all-core --gemfile Gemfile --gem-guess --chdir-first ' \
               "--innosetup #{ISS_FILE} --console --no-lzma " \
			   "--output #{OUT_FILE_NAME}"

File.open ISS_FILE, 'w' do |f|
  f.write <<-EOF
[Setup]
AppName=Twitrrerr
AppVersion=#{Twitrrerr::VERSION}
DefaultDirName={pf}\\Twitrrerr
DefaultGroupName=Twitrrerr
OutputBaseFilename=#{SETUP_FILE_NAME}

[Icons]
Name: "{group}\\Twitrrerr"; Filename: "{app}\\twitrrerr.exe"
Name: "{group}\\Uninstall Twitrrerr"; Filename: "{uninstallexe}"
EOF
end

puts "--> Building UI elements"

system "rake build_ui"

begin
  Dir.mkdir DIST_PATH
rescue Errno::EEXIST
end
puts "--> Creating setup binary"
system "ocra #{OCRA_OPTIONS} #{SCRIPT_FILE}"

puts "--> Cleanup"
File.delete ISS_FILE
