require 'json'
require 'pp'
require 'rest-client'
require 'csv'
require 'gooddata'

GD_AUTH_TOKEN = 'AUTH-TOKEN'

GoodData.with_connection('username@company.com', 'password') do |c|
    
    # Read the data model and create a project from blueprint
    
    blueprint = eval(File.read('./model/model.rb'))
    
    project = GoodData::Project.create_from_blueprint(blueprint, :auth_token => GD_AUTH_TOKEN)
    puts "Created project #{project.pid}"
    
    #Store project id to file for later use (update data)
    
    goodfile = {
        "project_id" => project.pid,
        "model" => "./model/model.rb"
    }
    
    File.open("Goodfile","w") do |f|
        f.write(goodfile.to_json)
    end
    
    GoodData::with_project(project.pid) do |p|
        # Load data
        GoodData::Model.upload_data('./data/tweets.csv', blueprint, 'tweets')
        
        puts "Data Uploaded"
        
        # Create  metrics
        
        retweet_sum = p.facts('fact.tweets.retweets').create_metric(:type => :sum)
        retweet_sum.save
        
        tweet_count = p.attributes('attr.tweets.factsof').create_metric(:type => :count)
        tweet_count.save
        
        puts "Metrics created"
        
        # Create reports
        
        #tweets_by_hour = p.add_report(title: '# Tweets by Hour', top: [tweet_count], left: ['attr.tweets.hour'])
        #tweets_by_hour.save
        #
        #number_of_retweets = p.add_report(title: '# Retweets', top: [retweet_sum])
        #number_of_retweets.save
        #
        #number_of_tweets = p.add_report(title: '# Tweets', top: [tweet_count])
        #number_of_tweets.save
        
        top_tweets = p.add_report(title: 'Top Tweets', top: [retweet_sum], left: ['attr.tweets.tweet'])
        top_tweets.save
        
        top_users_retweets = p.add_report(title: 'Top Users by Retweets', top: [retweet_sum], left: ['attr.tweets.user'])
        top_users_retweets.save
        
        top_users_tweets = p.add_report(title: 'Top Users by Tweets', top: [tweet_count], left: ['attr.tweets.user'])
        top_users_tweets.save
        
        
        rd_tweets = {
            'reportDefinition' => {
                'content' => {
                    'grid' => {
                        'sort' => {
                            'columns' => [],
                            'rows' => []
                        },
                        'columnWidths' => [],
                        'columns' => ['metricGroup'],
                        'metrics' => [
                        {
                            'alias' => 'sum of tweets',
                            'uri' => GoodData::Metric[tweet_count].uri
                        }
                        ],
                        'rows' => []
                    },
                    'oneNumber' => {
                        'labels' => {
                            'description' => 'Tweet Count'
                        }
                    },
                    'format' => 'oneNumber',
                    'filters' => []
                },
                'meta' => {
                    'tags' => '',
                    'summary' => '',
                    'title' => 'Report Definition'
                }
            }
        }
        
        
        tweets = GoodData::ReportDefinition.new(rd_tweets)
        tweets.client = c
        tweets.project = p
        
        tweets_headline = p.add_report(:title =>  '# Tweets headline', :rd => tweets)
        #tweets_by_hour.save
        
        rd_retweets = {
            'reportDefinition' => {
                'content' => {
                    'grid' => {
                        'sort' => {
                            'columns' => [],
                            'rows' => []
                        },
                        'columnWidths' => [],
                        'columns' => ['metricGroup'],
                        'metrics' => [
                        {
                            'alias' => 'sum of retweets',
                            'uri' => GoodData::Metric[retweet_sum].uri
                        }
                        ],
                        'rows' => []
                    },
                    'oneNumber' => {
                        'labels' => {
                            'description' => 'Retweets Sum'
                        }
                    },
                    'format' => 'oneNumber',
                    'filters' => []
                },
                'meta' => {
                    'tags' => '',
                    'summary' => '',
                    'title' => 'Report Definition'
                }
            }
        }
        
        
        retweets = GoodData::ReportDefinition.new(rd_retweets)
        retweets.client = c
        retweets.project = p
        
        retweets_one_number = p.add_report(:title =>  'Retweets Headline', :rd => retweets)
        
        hour = GoodData::Attribute['attr.tweets.hour'].primary_label.uri
        
        line_chart_rd = {
            "reportDefinition" => {
                "content" => {
                    "chart" => {
                        "styles" => {
                            "global" => {'linetype' => 'smooth'}
                        },
                        "buckets" => {
                            "y" => [
                            {
                                "uri" => "metric"
                            }
                            ],
                            "color" => [],
                            "x" => [
                            {
                                "uri" => hour
                                
                            }
                            ],
                            "angle" => []
                        },
                        "type" => "area"
                    },
                    "grid" => {
                        "sort" => {
                            "columns" => [],
                            "rows" => []
                        },
                        "columnWidths" => [],
                        "columns" => [
                        "metricGroup"
                        ],
                        "metrics" => [
                        {
                            "alias" => "count of Records of Tweets",
                            "uri" => GoodData::Metric[tweet_count].uri
                        }
                        ],
                        "rows" => [
                        {
                            "attribute" => {
                                "alias" => "",
                                "totals" => [
                                []
                                ],
                                "uri" => hour
                            }
                        }
                        ]
                    },
                    "oneNumber" => {
                        "labels" => {}
                    },
                    "format" => "chart",
                    "filters" => []
                },
                "meta" => {
                    "tags" => "",
                    "summary" => "",
                    "title" => "Untitled report definition",
                }
            }
        }
        
        line_chart = GoodData::ReportDefinition.new(line_chart_rd)
        line_chart.client = c
        line_chart.project = p
        
        tweets_by_hour = p.add_report(:title =>  'Tweets by Hour', :rd => line_chart)
        
        puts "Reports created"
        
        # Prepare dashboard payload - should be easier in the future
        
        dashboard_payload =  {
            "projectDashboard" => {
                "content" => {
                    "tabs" => [
                    {
                        "identifier" => "8e728fbbfea3",
                        "title" => "Overview",
                        "items" => [
                        {
                            "iframeItem" => {
                                "positionX" => 0,
                                "sizeY" => 130,
                                "sizeX" => 470,
                                "url" => "https://s3.amazonaws.com/gd-images.gooddata.com/customtext/magic.html?bodycolor=2BDCFF",
                                "positionY" => 0
                            }
                        },
                        {
                            "iframeItem" => {
                                "positionX" => 460,
                                "sizeY" => 130,
                                "sizeX" => 480,
                                "url" => "https://s3.amazonaws.com/gd-images.gooddata.com/customtext/magic.html?bodycolor=2BDCFF",
                                "positionY" => 0
                            }
                        },
                        {
                            "reportItem" => {
                                "obj" => GoodData::Report[retweets_one_number].uri,
                                "sizeY" => 100,
                                "sizeX" => 450,
                                "style" => {
                                    "displayTitle" => 1,
                                    "background" => {
                                        "opacity" => 0
                                    }
                                },
                                "visualization" => {
                                    "grid" => {
                                        "columnWidths" => []
                                    },
                                    "oneNumber" => {
                                        "labels" => {
                                            "description" => "Retweets"
                                        }
                                    }
                                },
                                "positionY" => 10,
                                "filters" => [],
                                "positionX" => 480
                            }
                        },{
                            "reportItem" => {
                                "obj" => GoodData::Report[tweets_headline].uri,
                                "sizeY" => 100,
                                "sizeX" => 450,
                                "style" => {
                                    "displayTitle" => 1,
                                    "background" => {
                                        "opacity" => 0
                                    }
                                },
                                "visualization" => {
                                    "grid" => {
                                        "columnWidths" => []
                                    },
                                    "oneNumber" => {
                                        "labels" => {
                                            "description" => "Retweets"
                                        }
                                    }
                                },
                                "positionY" => 10,
                                "filters" => [],
                                "positionX" => 0
                            }
                        },{
                            "reportItem" => {
                                "obj" => GoodData::Report[tweets_by_hour].uri,
                                "sizeY" => 280,
                                "sizeX" => 940,
                                "style" => {
                                    "displayTitle" => 1,
                                    "background" => {
                                        "opacity" => 0
                                    }
                                },
                                "visualization" => {
                                    "grid" => {
                                        "columnWidths" => []
                                    },
                                    "oneNumber" => {
                                        "labels" => {
                                            "description" => "Retweets"
                                        }
                                    }
                                },
                                "positionY" => 140,
                                "filters" => [],
                                "positionX" => 0
                            }
                        },{
                            "reportItem" => {
                                "obj" => GoodData::Report[top_users_retweets].uri,
                                "sizeY" => 220,
                                "sizeX" => 470,
                                "style" => {
                                    "displayTitle" => 1,
                                    "background" => {
                                        "opacity" => 0
                                    }
                                },
                                "visualization" => {
                                    "grid" => {
                                        "columnWidths" => []
                                    },
                                    "oneNumber" => {
                                        "labels" => {
                                            "description" => "Retweets"
                                        }
                                    }
                                },
                                "positionY" => 440,
                                "filters" => [],
                                "positionX" => 0
                            }
                        },{
                            "reportItem" => {
                                "obj" => GoodData::Report[top_users_tweets].uri,
                                "sizeY" => 220,
                                "sizeX" => 310,
                                "style" => {
                                    "displayTitle" => 1,
                                    "background" => {
                                        "opacity" => 0
                                    }
                                },
                                "visualization" => {
                                    "grid" => {
                                        "columnWidths" => []
                                    },
                                    "oneNumber" => {
                                        "labels" => {
                                            "description" => "Retweets"
                                        }
                                    }
                                },
                                "positionY" => 440,
                                "filters" => [],
                                "positionX" => 320
                            }
                        },{
                            "reportItem" => {
                                "obj" => GoodData::Report[top_tweets].uri,
                                "sizeY" => 220,
                                "sizeX" => 310,
                                "style" => {
                                    "displayTitle" => 1,
                                    "background" => {
                                        "opacity" => 0
                                    }
                                },
                                "visualization" => {
                                    "grid" => {
                                        "columnWidths" => []
                                    },
                                    "oneNumber" => {
                                        "labels" => {
                                            "description" => "Retweets"
                                        }
                                    }
                                },
                                "positionY" => 440,
                                "filters" => [],
                                "positionX" => 630
                            }
                        },
                        {
                            "iframeItem" => {
                                "positionX" => 410,
                                "sizeY" => 100,
                                "sizeX" => 110,
                                "url" => "https://s3.amazonaws.com/gd-images.gooddata.com/customtext/magic.html?bodybordercolor=FFFFFF&imgurl=http%3A%2F%2Fwww.tripit.com%2Fblog%2Fwp-content%2Fuploads%2F2014%2F09%2Ftwitter-4096-black.png&maxwidth=100",
                                "positionY" => 0
                            }
                        }
                        ]
                    }
                    ],
                    "filters" => []
                },
                "meta"=> {
                    "tags"=> "",
                    "title"=> "Hackathon Twitter Dashboard"
                }
            }
        }
        
        # Create dashboard
        
        create_object_uri = "/gdc/md/#{project.pid}/obj"
        x = GoodData.post(create_object_uri, dashboard_payload)
        
        puts "Dashboard created"
        
    end
end
