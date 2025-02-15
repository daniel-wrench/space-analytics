# This script downloads data for all orbital rocket launches from the Space Devs
# Launch Library API. It then performs some tidying of the column names, adds
# a couple of derived variables, and saves both this and the raw data to CSVs.

library(httr)
library(jsonlite)
library(tidyverse)

# Define the base URL 
## Use lldev for testing with 1 year of data with no rate limits
## ll for full data but 15 calls/hour
launch_base_url <- "https://ll.thespacedevs.com/2.3.0/launches/"

# Get current time and time from 3 years ago
enddate <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
#startdate <- format(Sys.time() - 365 * 3 * 86400, "%Y-%m-%dT%H:%M:%S")

# Define filters
net_filters <- paste0("&net__lte=", enddate)
orbital_filter <- "include_suborbital=false"

# Other query parameters
mode <- "mode=normal" # Set mode to detailed to include all related objects
limit <- "limit=100" # Limit returned results to just 100 per query
ordering <- "ordering=net" # Ordering the results by ascending T-0 (NET)

# Assemble query URL
query_url <- paste0(launch_base_url, "?", net_filters, "&", 
                    orbital_filter, "&", mode, "&", limit, "&", ordering)

print(paste("query URL:",query_url))

# Function to get API results
get_results <- function(url) {
  response <- tryCatch({
    GET(url)
  }, error = function(e) {
    message("Request failed: ", e)
    return(NULL)
  })

  # Check for valid response
  if (!is.null(response) && status_code(response) == 200) {
    return(fromJSON(content(response, "text", encoding = "UTF-8"), flatten = TRUE))
  } else {
    message("Failed to fetch data. Status code: ", status_code(response))
    return(NULL)
  }
}

# Fetch initial results
results <- get_results(query_url)

# Check if results exist
if (is.null(results) || !"results" %in% names(results)) {
  stop("No data retrieved from API.")
}

# Handle pagination
all_results <- results$results
next_page <- results$`next` # Adds 100 to the offset each time

# Set rate limit parameters
start_time <- Sys.time()
max_calls_per_hour <- 5
calls_made <- 1 # Already made one call with initial query above
time_per_call <- 3600 / max_calls_per_hour  # 3600 seconds in an hour

while (!is.null(next_page)) {

  # Check if rate limit is reached
  if (calls_made >= max_calls_per_hour) {
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    wait_time <- max(0, 3600 - elapsed_time)  # Calculate remaining time in the hour
    message("Rate limit reached. Waiting for ", round(wait_time), " seconds...")
    Sys.sleep(wait_time)  # Pause to avoid exceeding the limit
    start_time <- Sys.time()  # Reset start time for the next batch
    calls_made <- 0
  }
  
  print(next_page)
  next_results <- get_results(next_page)
  
  if (!is.null(next_results) && "results" %in% names(next_results)) {
    all_results <- bind_rows(all_results, next_results$results)  # Append new data
    next_page <- next_results$`next` #Adds 100 to the offset of the query URL each time
    
    print("Latest range of dates of all_results:")
    print(paste(min(all_results$net),max(all_results$net)))
    
    
    calls_made <- calls_made + 1  # Increment API call count
    message("Calls made:", calls_made)
    
    # Wait before making the next call to spread out requests
    # Not really necessary right?
    #message("Waiting ", round(time_per_call), " seconds before next call...")
    #Sys.sleep(time_per_call)
    
  } else {
    next_page <- NULL
    print("All data retrieved from API")
  }
}

write_csv(all_results, "launches_raw.csv")

# Convert to DataFrame with relevant columns (plenty more available: just see names(all_results))
launch_df <- all_results |>
  transmute(
    name = name,
    net = net,
    status = status.name,
    statusAbbrev = status.abbrev,
    statusDescription = status.description,
    mission = mission.name,
    missionType = mission.type,
    missionDescription = mission.description,
    orbit = mission.orbit.name,
    rocket = rocket.configuration.name,
    launchServiceProvider = launch_service_provider.name,
    launchServiceProviderType = launch_service_provider.type,
    launchpad = pad.name,
    country = pad.location.country_code
  )

launch_df$date <- as.Date(launch_df$net)
launch_df$month <- floor_date(launch_df$date, "month")
launch_df$year <- floor_date(launch_df$date, "year")
launch_df$missionTypeStarlink <- ifelse(grepl("Starlink", launch_df$mission), "Starlink", "Other")

# Export the dataframe

write_csv(launch_df, "launches_cleaned.csv")
