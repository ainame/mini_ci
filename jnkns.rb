# -*- coding: utf-8 -*-
$:.unshift Dir.dirname(__FILE__) + '/lib'
require 'git'
require 'chatroid'
require 'date'

Chatroid.new do
  g = Git.new
  last_modified = DateTime.now

  on_time :sec => 0 do
    g.parse_log(g.log)
    # last_modifiedと比較する処理
    # テストを走らせる処理
  end
end.run!





