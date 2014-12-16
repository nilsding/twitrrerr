require 'twitrrerr/ui/compose_widget'

module Twitrrerr
  # Compose tweet widget.
  class ComposeWidget < Qt::Widget
    attr_reader :ui

    def initialize(parent = nil)
      super parent
      @ui = Ui::ComposeWidget.new
      @ui.setupUi self
    end
  end
end