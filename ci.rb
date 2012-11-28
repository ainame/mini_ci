# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__) + '/lib'
require 'git'
require 'chatroid'
require 'date'
require 'yaml'
require 'tempfile'
require 'active_support'
require 'active_support/all'

config = YAML.load(open('./setting.yaml').read)

def build(base_dir, target_dir)
  exit_status = false
  error_locations = ''
  Dir.chdir(base_dir) do
    test_result_source = `#{config['test_command']} #{target_dir}`
    exit_status        = $?.success?

    Tempfile.open('./tmp_test_result_source.txt') do |f|
      f.puts test_result_source
      f.flush
      serror_location = `perl ./test_error_location.pl < #{f.path}`
    end
  end

  return [exit_status, error_locations]
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
      result, error_locations = build(config['base_dir'], config['target_dir'])
      unless result
        privmsg config['channel'], ":" + "@all Failure!!!"

        error_locations.each_line do |line|
          notice config['channel'], ":" + line
        end

        notice config['channel'], ":" + "--this cause these commits--"
        commits = []
        g.blobs.each do |blob|
          next unless blob.date <= @last_modified
          notice config['channel'], ":" + "#{blob.author}: #{blob.message}"
          commits.push blob.commit
        end

        if config[:git_web_base_url]
          commitdiff_url = "#{config[:git_web_base_url]}a=commitdiff&h=#{commits.first}&"
          commitdiff_url .= "hp=#{commits.last}" if commits.size > 1
          notice config['channel'], ":  " + commitdiff_url
        else
          notice config['channel'], ":  " + "#{commits.last}..#{commits.first}"
        end
        
      else
        #notice CHANNEL, ":" + 'Success...'
      end
      @last_modified = g.blobs.first.date
    end
  end
end.run!
