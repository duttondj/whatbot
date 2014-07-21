require 'rufus-scheduler'
require 'time'
require_relative 'a_reminder'

module Cinch
module Plugins
class Reminder
    include Cinch::Plugin

    Day_reg = /days?|d/
    Hour_reg = /hours?|hrs?|h/
    Week_reg = /weeks?|wks?|w/
    Year_reg = /years?|yrs?|y/
    Minute_reg = /minutes?|mins?|m/
    Second_reg = /seconds?|secs?|s/
    Time_unit_reg = Regexp.union(Day_reg, Hour_reg, Week_reg, Year_reg, Minute_reg, Second_reg)

    match /remind me in (?<times>([[:digit:]]+ *#{Time_unit_reg} +(and)? *)+)(?<text>.*)/, use_prefix: false

    def initialize(*args)
        super
        @scheduler = Rufus::Scheduler.new
        @reminders = []
        File.open('reminders.csv', 'r').each do |line|
            # We control the format of the file so we don't need fancy CSV
            # features, so split is fine.
            row = line.split(',', 5)
            remind_at = Time.parse(row[3])
            add_reminder(row[0], row[1], row[2], Time.parse(row[3]), row[4])
        end
    end

    def execute(m, times, text)
        time_list = parse_time_list(times)

        time_to_add = 0
        time_list.each_slice(2) do |time|
            quantity = is_int? time[0]
            time_unit = parse_time_unit time[1]
            if quantity and time_unit
                time_to_add += quantity * time_unit
            else
                m.reply "Invalid time format. Reminder not set."
                return
            end
        end

        time_was = Time.now
        remind_at = time_was + time_to_add
        add_reminder(m.channel, m.user, time_was, remind_at, text, time_to_add)
        m.reply "Okay, I'll remind you about that on #{remind_at}"
    end

    private
    def add_reminder(channel, sender, created_at, remind_at, text, time_to_add=nil)
        time_to_add = remind_at - Time.now if time_to_add.nil?
        return unless time_to_add > 0
        reminder = AReminder.new(channel, sender, created_at, remind_at, text)
        @reminders << reminder
        @scheduler.in "#{time_to_add}s" do
            @reminders.delete_if { |reminder| reminder.remind_at <= Time.now }
            reminder.send(@bot)
        end

        save_reminders
    end

    def is_int?(given_str)
        begin
            return Integer(given_str)
        rescue
            return nil
        end
    end

    def parse_time_list(times)
        to_return = []
        current_item = ''
        last_type = :whitespace
        times.each_char do |char|
            if char == ' '
                last_type = :whitespace
                unless current_item == '' || current_item == 'and'
                    to_return << current_item
                end
                current_item = ''
            elsif char =~ /[[:alpha:]]/
                if last_type == :digit
                    to_return << current_item
                    current_item = ''
                end
                current_item += char
                last_type = :alpha
            else
                current_item += char
                last_type =:digit
            end
        end

        unless current_item == '' || current_item == 'and'
            to_return << current_item
        end

        return to_return
    end

    def parse_time_unit(str_unit)
        if str_unit =~ /^#{Day_reg}/
            return 24*60*60
        elsif str_unit =~ /^#{Hour_reg}/
            return 60*60
        elsif str_unit =~ /^#{Week_reg}/
            return 7*24*60*60
        elsif str_unit =~ /^#{Year_reg}/
            return 365*24*60*60
        elsif str_unit =~ /^#{Minute_reg}/
            return 60
        elsif str_unit =~ /^#{Second_reg}/
            return 1
        end

        return nil
    end

    def save_reminders
        File.open('reminders.csv', 'w') do |file|
            @reminders.each do |reminder|
                file.puts(reminder.to_csv_s) if reminder.remind_at > Time.now
            end
        end
    end
end
end
end

