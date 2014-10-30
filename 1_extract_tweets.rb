require 'twitter'
require 'csv'

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ""
  config.consumer_secret     = ""
  config.access_token        = ""
  config.access_token_secret = ""
end

CSV.open("./data/tweets.csv", "ab") do |csv|
  csv << ["tweet", "favorites", "retweets", "user", "date", "hour"]
end

client.search("#hackathonbi", :result_type => "all").each do |tweet|
	CSV.open("./data/tweets.csv", "ab") do |csv|
		csv << [tweet.text, tweet.favorite_count, tweet.retweet_count, tweet.user.screen_name, tweet.created_at.day.to_s+"/"+tweet.created_at.month.to_s+"/"+tweet.created_at.year.to_s, tweet.created_at.hour.to_s]
	end
end

puts "Tweets has been downloaded and prepared for upload"