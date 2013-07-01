# encoding: UTF-8
require './weibo_config'

client = WeiboOAuth2::Client.new

client.get_token_from_hash(WEIBO_CONFIG)

# client.statuses.update("Test!")

file_path = '/Users/wfeng/Documents/41-FpgWe5OL.jpg'

file_info = {
  :filename => File.basename(file_path),
  :type => 'image/jpeg',
  :name => 'file',
}

client.statuses.upload('Test Picture', File.open(file_path), file_info)

