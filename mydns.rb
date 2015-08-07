#!/usr/bin/env ruby
##
require 'rubydns'
require 'logger'
#require 'yaml'
require_relative 'lib/myresolver'

require 'yaml'
config=YAML.load(File.open('_config.yml'))

INTERFACES = [
    [:udp, "127.0.0.1", 53],
    [:tcp, "127.0.0.1", 53]
]
Name = Resolv::DNS::Name
IN = Resolv::DNS::Resource::IN


#file = open('mydns.log', File::WRONLY | File::APPEND | File::CREAT)
#logger = Logger.new(file)
logger = Logger.new(config["home_directory"]+'/'+config["logfile"])
logger.level = Logger::DEBUG
logger.datetime_format = "%Y-%m-%d %H:%M:%S"
logger.formatter = proc { |severity, datetime, progname, msg|
    "#{datetime}: #{msg}\n"
}


# Use upstream DNS for name resolution.
#mainland = RubyDNS::Resolver.new([ [:udp, "192.168.2.1", 53]])
#oversea = RubyDNS::Resolver.new([ [:tcp, "8.8.8.8", 53]])
#myresolver = MyResolver.new([[:udp, "192.168.2.1", 53],[:tcp, "106.185.41.36", 53]])
#myresolver = MyResolver.new([[:udp, "192.168.2.1", 53]])
#oversea_resolver = MyResolver.new([:q:[:tcp, "8.8.8.8", 53],[:tcp, "151.236.20.236", 53],[:tcp, "106.185.41.36", 53]])
oversea_resolver = MyResolver.new([[:tcp, "127.0.0.1", 5533]],:logger=>logger)

begin
    # Start the RubyDNS server
    RubyDNS::run_server(:listen => INTERFACES) do
        match(/test\.mydomain\.org/, IN::A) do |transaction|
            transaction.respond!("10.0.0.80")
        end

        # Default DNS handler
        otherwise do |transaction|
            transaction.passthrough!(oversea_resolver)
        end
    end
ensure
  oversea_resolver.close_file
end