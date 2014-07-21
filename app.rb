# encoding: utf-8
require 'cinch'
require 'cinch/extensions/authentication'
require 'cinch/plugins/identify'
require 'cinch/plugins/imdb'
require 'cinch/plugins/media'
require 'cinch/plugins/lastfm'
require 'cinch/plugins/links'
require 'cinch/plugins/whatcd'
require 'cinch/plugins/big_brother'
require 'cinch/plugins/urbandictionary'
require 'cinch/plugins/recommend'
require 'cinch/plugins/weather'
require 'cinch/plugins/title'
require 'cinch/plugins/search'
require 'cinch/plugins/misc'
require 'cinch/plugins/reminder'

require 'dotenv'
Dotenv.load

# Set up DataMapper
require 'data_mapper'
require 'bitches/models'

DataMapper.setup :default, ENV['DATABASE_URL']
DataMapper.finalize
DataMapper.auto_upgrade!

# Set up the Cinch::Bot
bot = Cinch::Bot.new do
  configure do |c|
    c.server   = ENV['SERVER']
    c.port     = ENV['PORT']
    c.password = ENV['PASSWORD']
    c.nick     = ENV['NICKNAME']
    c.user     = ENV['NICKNAME']
    c.channels = [ENV['CHANNEL'], ENV['MONITOR_CHANNEL']]
    c.ssl.use  = true if ENV['SSL'] == "true"

    c.authentication = Cinch::Configuration::Authentication.new
    c.authentication.strategy = :channel_status
    c.authentication.level    = :h
    c.authentication.channel  = ENV['CHANNEL']
    
    c.plugins.plugins = [Cinch::Plugins::Links, Cinch::Plugins::UrbanDictionary, 
      Cinch::Plugins::Recommend, Cinch::Plugins::Weather, Cinch::Plugins::Title,
      Cinch::Plugins::Search, Cinch::Plugins::Misc, Cinch::Plugins::Reminder]

    c.plugins.plugins << Cinch::Plugins::IMDb
    c.plugins.options[Cinch::Plugins::IMDb] = {
      :standard => lambda do |movie|
        msg  = movie.title.dup
        msg << " (#{movie.release_date.year})" unless movie.release_date.nil?
        msg << " - #{Integer(movie.runtime) / 60} min" unless movie.runtime.nil?
        msg << " - #{('★' * movie.rating + '☆' * 10)[0..9]}" unless movie.rating.nil?
        msg << " - #{movie.plot}" unless movie.plot.nil?
        
        unless movie.genres.nil?
          msg << " http://www.imdb.com/title/#{movie.imdb_id}/"
        end

        return msg
      end,
      :fact => lambda do |movie, fact, result|
        result = "#{Integer(movie.runtime) / 60} min" if fact == 'runtime'
        "#{movie.title.capitalize} #{fact}: #{result}"
      end
    }
    
    c.plugins.plugins << Cinch::Plugins::Identify
    c.plugins.options[Cinch::Plugins::Identify] = {
      :password => ENV['NICKSERV_PASSWORD'] || '',
      :type     => :nickserv,
    }

    c.plugins.plugins << Cinch::Plugins::LastFM
    c.plugins.options[Cinch::Plugins::LastFM] = {
      :api_key    => ENV['LASTFM_KEY'],
      :api_secret => ENV['LASTFM_SECRET'],
      :allowchans => ENV['ALLOW_CHANS']
    }
    
    c.plugins.plugins << Cinch::Plugins::Media
    c.plugins.options[Cinch::Plugins::Media] = {
      :url           => ENV['GALLERY_URL'],
      :secret        => ENV['GALLERY_SECRET'],
      :channels      => [ENV['CHANNEL']],
      :ignored_hosts => ['https://fbcdn-sphotos-c-a.akamaihd.net/'],
      :ignored_tags  => [/nsfw/i, /nsfl/i, / personal/i, /ignore/i]
    }

    c.plugins.plugins << Cinch::Plugins::What
    c.plugins.options[Cinch::Plugins::What] = {
      :username => ENV['WHATCD_USERNAME'],
      :password => ENV['WHATCD_PASSWORD']
    }

    c.plugins.plugins << Cinch::Plugins::BigBrother
    c.plugins.options[Cinch::Plugins::BigBrother] = {
      :channel => ENV['MONITOR_CHANNEL']
    }
  end

# Help message
  on :message, "!help" do |m|
    m.reply "See http://example.com/help.html"
  end

# Ping
  on :message, /^!(\S+)ing/i do |m, char|
    m.reply "#{char}ong"
  end

end

# Configure loggers
bot.loggers.level = :info

# Quit with an appropriate message
Signal.trap('SIGINT') { bot.quit "brb" }

# Start the Cinch::Bot
bot.start
