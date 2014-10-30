GoodData::Model::ProjectBlueprint.build("My Event Dashboard") do |p|
    p.add_date_dimension('date')

    p.add_dataset('tweets') do |d|
      d.add_attribute('tweet')
      d.add_fact('favorites')
      d.add_fact('retweets')
      d.add_attribute('user')
      d.add_date('date', :dataset => "date")
      d.add_attribute('hour')
      
  end
end
