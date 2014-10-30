Twitter Event Dashboard
==========================

This helps you to spin up the Dashboard for your Event so that you can analyze Twiiter activity.

1. You have to create [Twitter App](https://apps.twitter.com/) to obtain all credentials:

- Consumer Key
- Consumer Secret
- Access Token
- Access Token Secret

Use those credentials in **1_extract_tweets.rb**. 

2. You need to have GoodData authentication token and credentials. If you don't have one, you can sign up for [Trial Period](https://developer.gooddata.com/trial) and you can register to [GoodData for free](https://secure.gooddata.com/registration/).

Use GoodData token and credentials in **2_project_creation.rb** and **3_update_data.rb**

-------

1_extract_tweets.rb - this file extracts data from Twitter and prepares it for upload (store csv locally)
2_project_creation.rb - this file builds complete project and uploads the data
3_update_data.rb - this file uploads the data (you can run it periodically to refresh the dashboard)




