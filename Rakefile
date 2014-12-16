require 'yard'

UI_FILES = Rake::FileList.new("lib/**/ui/*.ui")

task :default => :build_ui

task :build_ui => UI_FILES.ext('.rb')

rule ".rb" => ".ui" do |t|
  sh "rbuic4 #{t.source} > #{t.name}"
end

YARD::Rake::YardocTask.new do |t|
  t.files = %w(lib/*.rb lib/twitrrerr/*.rb - *.md LICENSE)
end