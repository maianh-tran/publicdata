# This code seems to work up til 2021

library(httr)
library(readxl)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# =========================================
# Pull HUDs zip to county/cbsa/cd crosswalks
# =========================================

# API Token
api_token <- "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI2IiwianRpIjoiNTBhYzE3NDdiMGIzZmI2MDEyZmNkNzllMzIyMGJhYzUyNTJlNzUwYmY0OWVmNWY5ZTU1YTU5Y2UyZjZlOGY0MTZiZTZlYjc5YmE1YjJhMzQiLCJpYXQiOjE3MjA1NTY2OTguMjUzMTQ0LCJuYmYiOjE3MjA1NTY2OTguMjUzMTQ2LCJleHAiOjIwMzYwODk0OTguMjQ5MTQ0LCJzdWIiOiI3MzY2NiIsInNjb3BlcyI6W119.dsqzSY7ekZE-mnpgVJGBHG6MdZ_4sGngPGN2F0RFMjSJb_S3i6C-TYyce65xCGSFQETMJF18ZhbshN2znBXAAw"

# Function to generate URLs for given years and quarters
generate_urls <- function(start_year, end_year, pattern) {
  years <- start_year:end_year
  quarters <- c("03", "06", "09", "12") # Quarters
  urls <- c()
  for (year in years) {
    for (quarter in quarters) {
      # Create the quarter-year string
      quarter_year <- paste0(quarter, year)
      # Construct the URL
      url <- paste0("https://www.huduser.gov/portal/datasets/usps/", pattern, "_", quarter_year, ".xlsx")
      urls <- c(urls, url)
    }
  }
  return(urls)
}

# Download directories
download_directory <- paste0(rootdir,"/crosswalk_spatial/rawdata/zip_crosswalk")

# Function to download and read crosswalk files
download_and_read_crosswalks <- function(urls, directory) {
  crosswalk_data_list <- lapply(urls, function(url) {
    # Extract file name from URL
    file_name <- basename(url)
    
    # File path to save the file
    file_path <- file.path(directory, file_name)
    
    # Download the file with the API token in the headers
    response <- GET(url, add_headers(Authorization = paste("Bearer", api_token)), write_disk(file_path, overwrite = TRUE))
    
    if (status_code(response) == 200) {
      cat("Downloaded and saved as", file_name, "\n")
      # Read the Excel file
      read_excel(file_path)
    } else if (status_code(response) == 404) {
      cat("Not found (404):", url, "\n")
      NULL
    } else {
      cat("Failed to download the file. Status code:", status_code(response), "\n")
      NULL
    }
  })
  return(crosswalk_data_list)
}

# Generate the URLs
urls_zipcounty <- generate_urls(2010, 2021, "zip_county")
urls_zipcbsa <- generate_urls(2010, 2021, "zip_cbsa")
urls_zipcd <- generate_urls(2010, 2021, "zip_cd")
urls_ziptract <- generate_urls(2010, 2021, "zip_tract")
urls_countyzip <- generate_urls(2010, 2021, "county_zip")
urls_cbsazip <- generate_urls(2010, 2021, "cbsa_zip")
urls_cdzip <- generate_urls(2010, 2021, "cd_zip")
urls_tractzip <- generate_urls(2010, 2021, "tract_zip")

# Download and read the files
zipcounty <- download_and_read_crosswalks(urls_zipcounty, download_directory)
zipcbsa <- download_and_read_crosswalks(urls_zipcbsa, download_directory)
zipcd <- download_and_read_crosswalks(urls_zipcd, download_directory)
ziptract <- download_and_read_crosswalks(urls_ziptract, download_directory)
countyzip <- download_and_read_crosswalks(urls_countyzip, download_directory)
cbsazip <- download_and_read_crosswalks(urls_cbsazip, download_directory)
cdzip <- download_and_read_crosswalks(urls_cdzip, download_directory)
tractzip <- download_and_read_crosswalks(urls_tractzip, download_directory)

# Combine the data if necessary (example assumes all files have the same structure)
# combined_data <- do.call(rbind, crosswalk_data_list)

# View the first few rows of the combined data (if combined)
# head(combined_data)