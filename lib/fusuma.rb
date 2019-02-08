require_relative 'fusuma/version'
require_relative 'fusuma/event_stack'
require_relative 'fusuma/gesture_event'
require_relative 'fusuma/command_executor'
require_relative 'fusuma/swipe.rb'
require_relative 'fusuma/pinch.rb'
require_relative 'fusuma/tap.rb'
require_relative 'fusuma/multi_logger'
require_relative 'fusuma/config.rb'
require_relative 'fusuma/device.rb'
require_relative 'fusuma/libinput_commands.rb'
require 'logger'
require 'open3'
require 'yaml'

# this is top level module
module Fusuma
  # main class
  class Runner
    class << self
      def run(option = {})
        set_trap
        read_options(option)
        instance = new
        instance.run
      end

      private

      def set_trap
        Signal.trap('INT') { puts exit } # Trap ^C
        Signal.trap('TERM') { puts exit } # Trap `Kill `
      end

      def read_options(option)
        print_version && exit(0) if option[:version]
        print_device_list if option[:list]
        reload_custom_config(option[:config_path])
        debug_mode if option[:verbose]
        Device.given_device = option[:device]
        Process.daemon if option[:daemon]
      end

      def print_version
        MultiLogger.info '---------------------------------------------'
        MultiLogger.info "Fusuma: #{Fusuma::VERSION}"
        MultiLogger.info "libinput: #{LibinputCommands.new.version}"
        MultiLogger.info "OS: #{`uname -rsv`}".strip
        MultiLogger.info "Distribution: #{`cat /etc/issue`}".strip
        MultiLogger.info "Desktop session: #{`echo $DESKTOP_SESSION`}".strip
        MultiLogger.info '---------------------------------------------'
      end

      def print_device_list
        puts Device.names
        exit(0)
      end

      def reload_custom_config(config_path = nil)
        return unless config_path
        MultiLogger.info "use custom path: #{config_path}"
        Config.instance.custom_path = config_path
        Config.reload
      end

      def debug_mode
        print_version
        MultiLogger.instance.debug_mode = true
      end
    end

    def initialize
      @event_stack = EventStack.new
    end

    def run
      LibinputCommands.new.debug_events do |line|
        gesture_event = GestureEvent.initialize_by(line.to_s, Device.ids)
        next unless gesture_event
        @event_stack << gesture_event
        @event_stack.generate_command_executor.tap { |c| c.execute if c }
      end
    end
  end
end
