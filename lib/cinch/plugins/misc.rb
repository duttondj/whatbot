require 'cinch'
require_relative 'weather'

module Cinch
  module Plugins
    class Misc
      include Cinch::Plugin

      set :plugin_name, 'misc'

      match /getchan/i,                         :method => :getchan
      match /topic/i,				:method => :gettopic
      match /coham/i,				:method => :coham
	  
      def getchan(m)
        m.reply "This channel is called #{m.channel}"
      end

      def gettopic(m)
        m.reply m.channel.topic
      end

      def coham(m)
        m.reply "!compare #{m.user} moham"
      end

    end
  end
end
