# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__) + '/lib'
require 'git'
require 'chatroid'
require 'date'
require 'yaml'
require 'active_support'
require 'active_support/all'

config = YAML.load(open('./setting.yaml').read)

def build(base_dir, target_dir)
  exit_status = false
  Dir.chdir(base_dir) do
    exit_status = system "#{config['test_command']} #{target_dir}"
  end

  exit_status
end

Chatroid.new do
  set :service,  "Irc"
  set :server,   config['server']
  set :port,     config['port']
  set :channel,  config['channel']
  set :username, config['username']

  @last_modified = DateTime.now

  on_time :min => [0,5,10,15,20,25,30,35,40,45,50,55], :sec => 0 do
    g = Git.new(config['base_dir'])
    begin
      g.evaluate_with_base_dir do |git|
        git.pull config['remote'], config['branch']
        git.parse_log(git.log('--after', 1.day.ago.to_date.to_s))
      end
    rescue

    end

    # last_modifiedと比較する処理
    if g.blobs.first.respond_to?(:date) && g.blobs.first.date > @last_modified
      unless build(config['base_dir'], config['target_dir'])
        privmsg config['channel'], ":" + "@all Failure!!!"
      else
        #notice CHANNEL, ":" + 'Success...'
      end
      @last_modified = g.blobs.first.date
    end
  end
end.run!
