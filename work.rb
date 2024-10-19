# /env_test.rb
require "dotenv/load"
require "daru"
require "date"
require "http"
require "json"
require "ascii_charts"

puts "========================================
    Will you need an umbrella today?    
========================================"
puts "\n\nWhere are you?\n"

location= gets.chomp

#Getting the current time
current_time = Time.now
# Normalize to the current hour and add one hour if it's not exactly on the hour
next_full_hour = current_time + (3600 - (current_time.min * 60 + current_time.sec))
# Convert it to a timestamp for parsing
next_full_hour_timestamp = next_full_hour.to_i

#First Fetching the Coordinates of the Given Location

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
 # Formatting the output for Input in Pirate Weather
 location_data="/#{latitude},#{longitude}"
 
 
#Now getting the weather data from Pirate Weather

pirate_weather_api_key = ENV["PIRATE_WEATHER_KEY"]
# Assemble the full URL string by adding the first part, the API token, and the last part together
pirate_weather_url = "https://api.pirateweather.net/forecast/" + pirate_weather_api_key + location_data
# Place a GET request to the URL
raw_response = HTTP.get(pirate_weather_url)
parsed_response = JSON.parse(raw_response)

#Getting the current temperature
currently_hash = parsed_response.fetch("currently")
temperature=currently_hash.fetch("temperature")
temperature_C=(temperature-32)*5/9

#Getting the Weather Forecast
hourly = parsed_response.fetch("hourly").fetch("data")

#Setting up variables for storage
next_hours=[]
next_summaries=[]
next_precip_propability=[]
next_precip_propability10=[]

hourly.each do |data_hash|
  if data_hash.fetch("time") >= next_full_hour_timestamp && data_hash.fetch("time") < next_full_hour_timestamp +12*3600
    next_hours.push(data_hash.fetch("time")) 
    next_summaries.push(data_hash.fetch("summary"))
    next_precip_propability.push(data_hash.fetch("precipProbability"))
    if data_hash.fetch("precipProbability")>0.1
      next_precip_propability10.push(true)
    else
      next_precip_propability10.push(false)
    end
  elsif data_hash.fetch("time") >= next_full_hour_timestamp +12*3600
    break  # Exit the loop once the condition is met
  end
end

# Convert Unix timestamps to human-readable date and time (including hours)
formatted_times = next_hours.map { |timestamp| Time.at(timestamp).strftime("%m-%e-%y %H:%M") }

df = Daru::DataFrame.new({
  "Time" => formatted_times,
  "Summary" => next_summaries,
  "Propability" =>next_precip_propability,
  "Raining" => next_precip_propability10,
})


rains_next_12_hours=false
time_rain_starts=Date.new
counter=0


puts "Checking the weather at #{location}...."
puts "Your coordinates are #{latitude}, #{longitude}."
puts "It is currently #{temperature_C.round(2)}°C or #{temperature.round(2)}°F."
puts "Next hour: #{df['Summary'][0]}"

Rain_array = []  # Properly initializing the array

df["Raining"].each_with_index do |check, index|
  # Collecting hour and probability into Rain_array
  Rain_array.push([index + 1, (df['Propability'][index] * 100).to_i])
  if check == true
    rains_next_12_hours = true
  end
end

# Generating the ASCII chart
# Generating the ASCII chart with a fixed scale from 0 to 100
puts AsciiCharts::Cartesian.new(
  Rain_array,
  bar: true,
  hide_zero: true,
  min: 0,   # Set the minimum value for y-axis
  max: 100  # Set the maximum value for y-axis
).draw

if rains_next_12_hours==false
  puts "You probably won't need an umbrella."
else
  puts "You might want to take an umbrella!"
end
