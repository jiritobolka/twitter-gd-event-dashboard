require "json"
require 'pp'
require 'rest-client'
require 'csv'
require 'gooddata'

username = 'USERNAME'
password = 'PASSWORD'

json = JSON.parse(open("Goodfile").read)
project_id = json["project_id"]
#username = json["username"]
#password = json["password"]

blueprint = eval(File.read('./model/model.rb'))

#puts project_id
GoodData.with_connection(username, password) do |c|
  
  GoodData::with_project(project_id) do |p|
    # Load data
    GoodData::Model.upload_data('./data/tweets.csv', blueprint, 'tweets')
    puts "Data Uploaded"
	
	File.rename("./data/tweets.csv",DateTime.now.strftime('%d_%m_%Y')+"_tweets.csv")
	puts "Upload archived"
	
  end
end
