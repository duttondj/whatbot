require 'cinch'

module Cinch
module Plugins
class AReminder
    attr_reader :channel

    attr_reader :sender

    attr_reader :created_at

    attr_reader :remind_at

    attr_reader :text

    def initialize(channel, sender, created_at, remind_at, text)
        @channel = channel.to_s
        @sender = sender.to_s
        @created_at = created_at.to_s
        @remind_at = remind_at
        @text = text
    end

    def <=>(other)
        @remind_at <=> other.remind_at
    end

    def ==(other)
        if other.is_a?(AReminder)
            return ((@channel == other.channel) and
                    (@sender == other.sender) and
                    (@created_at == other.created_at) and
                    (@remind_at == other.remind_at) and
                    (@text == other.text))
        end

        return false
    end

    def send(bot)
        send_msg(bot, self.to_s)
    end

    def send_msg(bot, msg)
        if @channel.empty?
            user = Cinch::User.new(@sender, bot)
            user.send msg
        else
            channel = Cinch::Channel.new(@channel, bot)
            channel.send msg
        end
    end

    def to_s
        "#{@sender}: On #{@created_at}, you asked me to remind you #{@text}"
    end

    def to_csv_s
        "#{@channel},#{@sender},#{@created_at},#{@remind_at},#{@text}"
    end
end
end
end

