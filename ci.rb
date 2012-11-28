# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__) + '/lib'
require 'git'
require 'chatroid'
require 'date'
require 'yaml'
require 'tempfile'
require 'active_support'
require 'active_support/time'

Chatroid.new do
  @settings = YAML.load(open('./setting.yaml').read)
  @last_modified = DateTime.now

  set :service,  "Irc"
  set :server,   @settings['server']
  set :port,     @settings['port']
  set :channel,  @settings['channel']
  set :username, @settings['username']
  set :executed_dir, "#{Dir.pwd}"
  
  def build(base_dir, target_dir)
    exit_status = false
    error_locations = ''
    Dir.chdir(base_dir) do
      command = "#{@settings['test_command']} #{target_dir}"
      test_result_source = `#{command}`
      exit_status        = $?.success?
      Tempfile.open('tmp') do |f|
        f.puts test_result_source
        f.flush
        error_locations = `perl #{File.join(config[:executed_dir],'test_error_location.pl')} < #{f.path}`
      end
    end
    
    return [exit_status, error_locations]
  end

  on_time :min => [0,5,10,15,20,25,30,35,40,45,50,55], :sec => 0 do
    g = Git.new(@settings['base_dir'])
    begin
      g.evaluate_with_base_dir do |git|
        git.pull @settings['remote'], @settings['branch']
        git.parse_log(git.log('--after', 1.day.ago.to_date.to_s))
      end
    rescue

    end

    # last_modifiedと比較する処理
    if g.blobs.first.respond_to?(:date) && g.blobs.first.date > @last_modified
      result, error_locations = build(@settings['base_dir'], @settings['target_dir'])
      unless result
        privmsg @settings['channel'], ":" + "@all Failure!!!"

        error_locations.each_line do |line|
          notice @settings['channel'], ":" + line
        end

        notice @settings['channel'], ":" + "--this cause these commits--"
        commits = []
        g.blobs.each do |blob|
          if blob.date <= @last_modified
            commits.push blob.commit
            break
          end

          message = "#{blob.author.match(/\s*(.*)\s*<.*>/).captures[0].strip}: #{blob.message.strip}"
          notice @settings['channel'], ":" + message
          commits.push blob.commit
        end

        if @settings['git_web_base_url']
          commitdiff_url = "#{@settings['git_web_base_url']}a=commitdiff&h=#{commits.first}&"
          commitdiff_url += "hp=#{commits.last}" if commits.size > 1
          notice @settings['channel'], ":" + commitdiff_url
        else
          notice @settings['channel'], ":" + "#{commits.last}..#{commits.first}"
        end
        
      else
        #notice CHANNEL, ":" + 'Success...'
      end
      @last_modified = g.blobs.first.date
    end
  end
end.run!
