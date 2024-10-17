# /env_test.rb
require "dotenv/load"

#ENV.fetch("GMAPS_KEY")
#ENV.fetch("OPENAI_KEY")

#puts "========================================
#    Will you need an umbrella today?    
#========================================"
#puts "\n\nWhere are you\n"

#location= gets.chomp

location="Kassel"


# Pull in the HTTP class
require "http"
require "json"

current_time = Time.now
# Normalize to the current hour and add one hour if it's not exactly on the hour
next_full_hour = current_time + (3600 - (current_time.min * 60 + current_time.sec))

# Convert it to a timestamp for parsing
next_full_hour_timestamp = next_full_hour.to_i


raw_response=HTTP
  .follow(strict: false)
  .cookies(
    {
      "_ga_devsite" => "GA1.3.155261124.1728276899",
    }
  )
  .get(
    "https://maps.googleapis.com/maps/api/geocode/json",
    {
      :params => {
        "address" => location,
        "key" => ENV.fetch("GMAPS_KEY"),
      },
    }
  )


 
 parsed_response = JSON.parse(raw_response)
 
 results_data=parsed_response.fetch("results")
 geometry=results_data.at(0).fetch("geometry").fetch("location")

 latitude=geometry.fetch("lat")
 longitude=geometry.fetch("lng")


 location_data="/#{latitude},#{longitude}"
 


 # Hidden variables
pirate_weather_api_key = ENV["PIRATE_WEATHER_KEY"]

# Assemble the full URL string by adding the first part, the API token, and the last part together
pirate_weather_url = "https://api.pirateweather.net/forecast/" + pirate_weather_api_key + location_data

# Place a GET request to the URL
raw_response = HTTP.get(pirate_weather_url)

parsed_response = JSON.parse(raw_response)
#pp parsed_response.keys

#Getting the current temperature
currently_hash = parsed_response.fetch("currently")
temperature=currently_hash.fetch("temperature")

#Getting the Weather Forecast
hourly = parsed_response.fetch("hourly").fetch("data")

pp hourly.at(0).keys



hourly.each do |data_hash|
  if data_hash.fetch("time") == next_full_hour_timestamp
    next_hour = data_hash.fetch("summary")
    pp data_hash.fetch("summary")
    pp "I saved a forecast"
    break  # Exit the loop once the condition is met
  end
end

pp next_hour
