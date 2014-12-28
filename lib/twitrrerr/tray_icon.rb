module Twitrrerr
  # TrayIcon widget.
  class TrayIcon < Qt::SystemTrayIcon

    # Use DBus for notifications
    attr_reader :use_dbus

    def initialize(parent = nil)
      super parent
      @use_dbus = Qt::DBusConnection.sessionBus.connected?
      if @use_dbus
        @dbus_session = Qt::DBusConnection.session_bus
        puts "D-Bus IPC"
        puts "(c) 2008-2014 Red Hat, Inc.  All your moneys are belong to us!"
      end
    end

    # Shows a balloon message for the entry with the given +title+ and +message+.
    # +title+ and +message+ must be plain text strings.
    # @param title [String]
    # @param message [String]
    def showMessage(title, message, *_args)
      return super unless @use_dbus
      # see https://people.gnome.org/~mccann/docs/notification-spec/notification-spec-latest.html#protocol

      dbus_msg = Qt::DBusMessage.create_method_call("org.freedesktop.Notifications",
                                                    "/org/freedesktop/Notifications",
                                                    "org.freedesktop.Notifications",
                                                    'Notify')
      dbus_msg.arguments = [
          "Twitrrerr",  # app_name
          Qt::Variant.from_value(0, 'unsigned int'),
                        # replaces_id (this fucker MUST BE an unsigned int!)
          "",           # app_icon
          title,        # summary
          message,      # body
          [],           # actions
          {},           # hints
          10000         # expire_timeout
      ]
      reply = @dbus_session.call(dbus_msg)
      unless reply.errorMessage.nil?
        puts "DBus error: #{reply.errorMessage}"
      end
    end
  end
end