import pandas as pd
import requests


def get_country_data(country_code):
    """
    Retrieves population and GDP data for a given country code from the World Bank API.

    Args:
        country_code: The 3-letter ISO country code (e.g., "USA", "CAN", "GBR").

    Returns:
        A dictionary containing population and GDP data, or None if an error occurs.
        Example:
        {
            "population": 331002651,
            "gdp": 21433226000000.0
        }
    """
    try:
        population_url = f"http://api.worldbank.org/v2/country/{country_code}/indicator/SP.POP.TOTL?format=json&per_page=1"
        gdp_url = f"http://api.worldbank.org/v2/country/{country_code}/indicator/NY.GDP.MKTP.CD?format=json&per_page=1"

        population_response = requests.get(population_url)
        gdp_response = requests.get(gdp_url)

        population_response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        gdp_response.raise_for_status()

        population_data = population_response.json()[1]
        gdp_data = gdp_response.json()[1]

        if not population_data or not gdp_data:
            return None  # no data found

        population = None
        gdp = None

        if population_data[0] and population_data[0]["value"]:
            population = population_data[0]["value"]

        if gdp_data[0] and gdp_data[0]["value"]:
            gdp = gdp_data[0]["value"]

        if population is None and gdp is None:
            return None

        result = {}
        if population is not None:
            result["population"] = population
        if gdp is not None:
            result["gdp"] = gdp

        return result

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data: {e}")
        return None
    except (ValueError, KeyError, IndexError) as e:
        print(f"Error parsing data: {e}")
        return None


def get_country_dataframe(country_dict):
    """
    Creates a Pandas DataFrame of GDP and population data for countries in the given dictionary.

    Args:
        country_dict: A dictionary of country names and their 3-letter ISO codes.

    Returns:
        A Pandas DataFrame with columns 'Country', 'Population', and 'GDP'.
    """
    data = []
    for country_name, country_code in country_dict.items():
        country_data = get_country_data(country_code)
        if country_data:
            data.append(
                {
                    "Country": country_name,
                    "Population": country_data.get("population"),
                    "GDP": country_data.get("gdp"),
                }
            )
        else:
            data.append(
                {
                    "Country": country_name,
                    "Population": None,
                    "GDP": None,
                }
            )

    return pd.DataFrame(data)


# Example usage:
country_dict = {
    "United States": "USA",
    "United Kingdom": "GBR",
    "Japan": "JPN",
    "Italy": "ITA",
    "Canada": "CAN",
    "Australia": "AUS",
    "United Arab Emirates": "ARE",
    "Luxembourg": "LUX",
    "South Korea": "KOR",
    "New Zealand": "NZL",
    "Brazil": "BRA",
    "Poland": "POL",
    "Mexico": "MEX",
    "Israel": "ISR",
    "Romania": "ROU",
    "Bahrain": "BHR",
    "Singapore": "SGP",
    "Colombia": "COL",
    "France": "FRA",
    "Saudi Arabia": "SAU",
    "Rwanda": "RWA",
    "Nigeria": "NGA",
    "Czech Republic": "CZE",
    "Spain": "ESP",
    "Ecuador": "ECU",
    "India": "IND",
    "Argentina": "ARG",
    "Germany": "DEU",
    "Iceland": "ISL",
    "Netherlands": "NLD",
    "Bulgaria": "BGR",
    "Angola": "AGO",
    "Belgium": "BEL",
    "Greece": "GRC",
    "Uruguay": "URY",
    "Switzerland": "CHE",
    "Sweden": "SWE",
    "Slovenia": "SVN",
    "Lithuania": "LTU",
    "Peru": "PER",
    "Slovakia": "SVK",
    "Armenia": "ARM",
    "Dominican Republic": "DOM",
    "Estonia": "EST",
    "Cyprus": "CYP",
    "Chile": "CHL",
    "Denmark": "DNK",
    "Panama": "PAN",
    "Austria": "AUT",
    "Thailand": "THA",
    "Liechtenstein": "LIE",
    "Finland": "FIN",
}

print("Fetching data...")
df = get_country_dataframe(country_dict)
print(df.head())

# Get the rank of NZ in terms of GDP and Population
df["GDP Rank"] = df["GDP"].rank(ascending=False)
df["Population Rank"] = df["Population"].rank(ascending=False)
df[df["Country"] == "New Zealand"]
