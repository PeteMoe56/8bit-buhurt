class_name Cities
extends RefCounted
## WHERE THE CLUBS ACTUALLY ARE, on a real map.
##
## PETE, 14 Sep 2026: *"Let's go with real US cities so they can have a radius
## with the 'homesick'. Then have a little button for Europe with European cities
## for our international fans over there. I think little things like that will be
## great gems for this game."*
##
## The invented place names worked and could not do this. HOMESICK was a flat
## 7% away from home whether the away day was ninety miles or two thousand,
## because "Harrow" is not anywhere and the distance between two made-up towns is
## not a number. Real coordinates turn one trait into a road trip: a Detroit club
## at Cleveland is barely away, and the same club at Seattle has been on a plane.
##
## TWO REGIONS AND THE WHOLE LEAGUE LIVES IN ONE. Picking Europe does not give
## you a European club in an American league — it generates a European league,
## because a pyramid whose clubs are four thousand miles apart is not a pyramid,
## it is a travel budget. The region is chosen once, at the same moment as the
## city, and it is a property of the world.
##
## COORDINATES ARE CITY-CENTER, TO TWO DECIMALS. That is about a kilometer, which
## is three orders of magnitude finer than anything that reads it — the distance
## bands are hundreds of miles wide. Precision here is free and wrong numbers are
## the kind of thing a player from that city notices immediately.

enum Region { US, EU }

const REGION_NAME := {
	Region.US: "United States",
	Region.EU: "Europe",
}

## `area` is what a person says after the city name — the state, or the country.
## It is on the splash screen and on the club's own page, and it is the half that
## makes "Portland" mean something.
const US := [
	{"name": "New York", "area": "NY", "lat": 40.71, "lon": -74.01},
	{"name": "Los Angeles", "area": "CA", "lat": 34.05, "lon": -118.24},
	{"name": "Chicago", "area": "IL", "lat": 41.88, "lon": -87.63},
	{"name": "Houston", "area": "TX", "lat": 29.76, "lon": -95.37},
	{"name": "Phoenix", "area": "AZ", "lat": 33.45, "lon": -112.07},
	{"name": "Philadelphia", "area": "PA", "lat": 39.95, "lon": -75.17},
	{"name": "San Antonio", "area": "TX", "lat": 29.42, "lon": -98.49},
	{"name": "San Diego", "area": "CA", "lat": 32.72, "lon": -117.16},
	{"name": "Dallas", "area": "TX", "lat": 32.78, "lon": -96.80},
	{"name": "Austin", "area": "TX", "lat": 30.27, "lon": -97.74},
	{"name": "Jacksonville", "area": "FL", "lat": 30.33, "lon": -81.66},
	{"name": "Fort Worth", "area": "TX", "lat": 32.76, "lon": -97.33},
	{"name": "Columbus", "area": "OH", "lat": 39.96, "lon": -83.00},
	{"name": "Charlotte", "area": "NC", "lat": 35.23, "lon": -80.84},
	{"name": "Indianapolis", "area": "IN", "lat": 39.77, "lon": -86.16},
	{"name": "San Francisco", "area": "CA", "lat": 37.77, "lon": -122.42},
	{"name": "Seattle", "area": "WA", "lat": 47.61, "lon": -122.33},
	{"name": "Denver", "area": "CO", "lat": 39.74, "lon": -104.99},
	{"name": "Oklahoma City", "area": "OK", "lat": 35.47, "lon": -97.52},
	{"name": "Nashville", "area": "TN", "lat": 36.16, "lon": -86.78},
	{"name": "Washington", "area": "DC", "lat": 38.91, "lon": -77.04},
	{"name": "El Paso", "area": "TX", "lat": 31.76, "lon": -106.49},
	{"name": "Boston", "area": "MA", "lat": 42.36, "lon": -71.06},
	{"name": "Portland", "area": "OR", "lat": 45.52, "lon": -122.68},
	{"name": "Las Vegas", "area": "NV", "lat": 36.17, "lon": -115.14},
	{"name": "Detroit", "area": "MI", "lat": 42.33, "lon": -83.05},
	{"name": "Memphis", "area": "TN", "lat": 35.15, "lon": -90.05},
	{"name": "Louisville", "area": "KY", "lat": 38.25, "lon": -85.76},
	{"name": "Baltimore", "area": "MD", "lat": 39.29, "lon": -76.61},
	{"name": "Milwaukee", "area": "WI", "lat": 43.04, "lon": -87.91},
	{"name": "Albuquerque", "area": "NM", "lat": 35.08, "lon": -106.65},
	{"name": "Tucson", "area": "AZ", "lat": 32.22, "lon": -110.97},
	{"name": "Fresno", "area": "CA", "lat": 36.74, "lon": -119.79},
	{"name": "Sacramento", "area": "CA", "lat": 38.58, "lon": -121.49},
	{"name": "Kansas City", "area": "MO", "lat": 39.10, "lon": -94.58},
	{"name": "Atlanta", "area": "GA", "lat": 33.75, "lon": -84.39},
	{"name": "Omaha", "area": "NE", "lat": 41.26, "lon": -95.93},
	{"name": "Raleigh", "area": "NC", "lat": 35.78, "lon": -78.64},
	{"name": "Miami", "area": "FL", "lat": 25.76, "lon": -80.19},
	{"name": "Cleveland", "area": "OH", "lat": 41.50, "lon": -81.69},
	{"name": "Tulsa", "area": "OK", "lat": 36.15, "lon": -95.99},
	{"name": "Minneapolis", "area": "MN", "lat": 44.98, "lon": -93.27},
	{"name": "New Orleans", "area": "LA", "lat": 29.95, "lon": -90.07},
	{"name": "Pittsburgh", "area": "PA", "lat": 40.44, "lon": -80.00},
	{"name": "Cincinnati", "area": "OH", "lat": 39.10, "lon": -84.51},
	{"name": "St. Louis", "area": "MO", "lat": 38.63, "lon": -90.20},
	{"name": "Salt Lake City", "area": "UT", "lat": 40.76, "lon": -111.89},
	{"name": "Buffalo", "area": "NY", "lat": 42.89, "lon": -78.88},
]

const EU := [
	{"name": "London", "area": "England", "lat": 51.51, "lon": -0.13},
	{"name": "Paris", "area": "France", "lat": 48.86, "lon": 2.35},
	{"name": "Berlin", "area": "Germany", "lat": 52.52, "lon": 13.40},
	{"name": "Madrid", "area": "Spain", "lat": 40.42, "lon": -3.70},
	{"name": "Rome", "area": "Italy", "lat": 41.90, "lon": 12.50},
	{"name": "Warsaw", "area": "Poland", "lat": 52.23, "lon": 21.01},
	{"name": "Vienna", "area": "Austria", "lat": 48.21, "lon": 16.37},
	{"name": "Prague", "area": "Czechia", "lat": 50.08, "lon": 14.44},
	{"name": "Budapest", "area": "Hungary", "lat": 47.50, "lon": 19.04},
	{"name": "Amsterdam", "area": "Netherlands", "lat": 52.37, "lon": 4.90},
	{"name": "Brussels", "area": "Belgium", "lat": 50.85, "lon": 4.35},
	{"name": "Copenhagen", "area": "Denmark", "lat": 55.68, "lon": 12.57},
	{"name": "Stockholm", "area": "Sweden", "lat": 59.33, "lon": 18.07},
	{"name": "Oslo", "area": "Norway", "lat": 59.91, "lon": 10.75},
	{"name": "Helsinki", "area": "Finland", "lat": 60.17, "lon": 24.94},
	{"name": "Dublin", "area": "Ireland", "lat": 53.35, "lon": -6.26},
	{"name": "Lisbon", "area": "Portugal", "lat": 38.72, "lon": -9.14},
	{"name": "Barcelona", "area": "Spain", "lat": 41.39, "lon": 2.17},
	{"name": "Milan", "area": "Italy", "lat": 45.46, "lon": 9.19},
	{"name": "Munich", "area": "Germany", "lat": 48.14, "lon": 11.58},
	{"name": "Hamburg", "area": "Germany", "lat": 53.55, "lon": 9.99},
	{"name": "Cologne", "area": "Germany", "lat": 50.94, "lon": 6.96},
	{"name": "Frankfurt", "area": "Germany", "lat": 50.11, "lon": 8.68},
	{"name": "Naples", "area": "Italy", "lat": 40.85, "lon": 14.27},
	{"name": "Turin", "area": "Italy", "lat": 45.07, "lon": 7.69},
	{"name": "Marseille", "area": "France", "lat": 43.30, "lon": 5.37},
	{"name": "Lyon", "area": "France", "lat": 45.76, "lon": 4.84},
	{"name": "Bordeaux", "area": "France", "lat": 44.84, "lon": -0.58},
	{"name": "Seville", "area": "Spain", "lat": 37.39, "lon": -5.98},
	{"name": "Valencia", "area": "Spain", "lat": 39.47, "lon": -0.38},
	{"name": "Porto", "area": "Portugal", "lat": 41.15, "lon": -8.61},
	{"name": "Zagreb", "area": "Croatia", "lat": 45.81, "lon": 15.98},
	{"name": "Belgrade", "area": "Serbia", "lat": 44.79, "lon": 20.45},
	{"name": "Sofia", "area": "Bulgaria", "lat": 42.70, "lon": 23.32},
	{"name": "Bucharest", "area": "Romania", "lat": 44.43, "lon": 26.10},
	{"name": "Athens", "area": "Greece", "lat": 37.98, "lon": 23.73},
	{"name": "Krakow", "area": "Poland", "lat": 50.06, "lon": 19.94},
	{"name": "Gdansk", "area": "Poland", "lat": 54.35, "lon": 18.65},
	{"name": "Wroclaw", "area": "Poland", "lat": 51.11, "lon": 17.04},
	{"name": "Poznan", "area": "Poland", "lat": 52.41, "lon": 16.93},
	{"name": "Riga", "area": "Latvia", "lat": 56.95, "lon": 24.11},
	{"name": "Vilnius", "area": "Lithuania", "lat": 54.69, "lon": 25.28},
	{"name": "Tallinn", "area": "Estonia", "lat": 59.44, "lon": 24.75},
	{"name": "Bratislava", "area": "Slovakia", "lat": 48.15, "lon": 17.11},
	{"name": "Ljubljana", "area": "Slovenia", "lat": 46.06, "lon": 14.51},
	{"name": "Antwerp", "area": "Belgium", "lat": 51.22, "lon": 4.40},
	{"name": "Rotterdam", "area": "Netherlands", "lat": 51.92, "lon": 4.48},
	{"name": "Gothenburg", "area": "Sweden", "lat": 57.71, "lon": 11.97},
	{"name": "Edinburgh", "area": "Scotland", "lat": 55.95, "lon": -3.19},
	{"name": "Manchester", "area": "England", "lat": 53.48, "lon": -2.24},
]


## HOMETOWNS, NOT LEAGUE TOWNS (Pete, 2 Oct 2026 playtest: "A LOT of hometowns
## are missing. Some states only have one city."). Every state now has at least
## two; the player's hometown is picked from US and these. The league's rival
## clubs are still drawn from US alone (`league_names`), so a seed builds the
## same pyramid it always did.
const US_TOWNS := [
	{"name": "Birmingham", "area": "AL", "lat": 33.52, "lon": -86.80},
	{"name": "Montgomery", "area": "AL", "lat": 32.37, "lon": -86.30},
	{"name": "Huntsville", "area": "AL", "lat": 34.73, "lon": -86.59},
	{"name": "Mobile", "area": "AL", "lat": 30.69, "lon": -88.04},
	{"name": "Tuscaloosa", "area": "AL", "lat": 33.21, "lon": -87.57},
	{"name": "Anchorage", "area": "AK", "lat": 61.22, "lon": -149.90},
	{"name": "Fairbanks", "area": "AK", "lat": 64.84, "lon": -147.72},
	{"name": "Juneau", "area": "AK", "lat": 58.30, "lon": -134.42},
	{"name": "Mesa", "area": "AZ", "lat": 33.42, "lon": -111.83},
	{"name": "Flagstaff", "area": "AZ", "lat": 35.20, "lon": -111.65},
	{"name": "Scottsdale", "area": "AZ", "lat": 33.49, "lon": -111.93},
	{"name": "Little Rock", "area": "AR", "lat": 34.75, "lon": -92.29},
	{"name": "Fayetteville", "area": "AR", "lat": 36.06, "lon": -94.16},
	{"name": "Fort Smith", "area": "AR", "lat": 35.39, "lon": -94.40},
	{"name": "Jonesboro", "area": "AR", "lat": 35.84, "lon": -90.70},
	{"name": "San Jose", "area": "CA", "lat": 37.34, "lon": -121.89},
	{"name": "Oakland", "area": "CA", "lat": 37.80, "lon": -122.27},
	{"name": "Colorado Springs", "area": "CO", "lat": 38.83, "lon": -104.82},
	{"name": "Boulder", "area": "CO", "lat": 40.01, "lon": -105.27},
	{"name": "Fort Collins", "area": "CO", "lat": 40.59, "lon": -105.08},
	{"name": "Pueblo", "area": "CO", "lat": 38.25, "lon": -104.61},
	{"name": "Hartford", "area": "CT", "lat": 41.76, "lon": -72.69},
	{"name": "New Haven", "area": "CT", "lat": 41.31, "lon": -72.92},
	{"name": "Bridgeport", "area": "CT", "lat": 41.19, "lon": -73.20},
	{"name": "Stamford", "area": "CT", "lat": 41.05, "lon": -73.54},
	{"name": "Wilmington", "area": "DE", "lat": 39.74, "lon": -75.55},
	{"name": "Dover", "area": "DE", "lat": 39.16, "lon": -75.52},
	{"name": "Tampa", "area": "FL", "lat": 27.95, "lon": -82.46},
	{"name": "Orlando", "area": "FL", "lat": 28.54, "lon": -81.38},
	{"name": "Tallahassee", "area": "FL", "lat": 30.44, "lon": -84.28},
	{"name": "Pensacola", "area": "FL", "lat": 30.42, "lon": -87.22},
	{"name": "Gainesville", "area": "FL", "lat": 29.65, "lon": -82.32},
	{"name": "Savannah", "area": "GA", "lat": 32.08, "lon": -81.09},
	{"name": "Augusta", "area": "GA", "lat": 33.47, "lon": -81.97},
	{"name": "Macon", "area": "GA", "lat": 32.84, "lon": -83.63},
	{"name": "Valdosta", "area": "GA", "lat": 30.83, "lon": -83.28},
	{"name": "Honolulu", "area": "HI", "lat": 21.31, "lon": -157.86},
	{"name": "Hilo", "area": "HI", "lat": 19.72, "lon": -155.08},
	{"name": "Boise", "area": "ID", "lat": 43.62, "lon": -116.20},
	{"name": "Idaho Falls", "area": "ID", "lat": 43.49, "lon": -112.03},
	{"name": "Pocatello", "area": "ID", "lat": 42.87, "lon": -112.45},
	{"name": "Coeur d'Alene", "area": "ID", "lat": 47.68, "lon": -116.78},
	{"name": "Peoria", "area": "IL", "lat": 40.69, "lon": -89.59},
	{"name": "Rockford", "area": "IL", "lat": 42.27, "lon": -89.09},
	{"name": "Champaign", "area": "IL", "lat": 40.12, "lon": -88.24},
	{"name": "Naperville", "area": "IL", "lat": 41.75, "lon": -88.15},
	{"name": "Fort Wayne", "area": "IN", "lat": 41.08, "lon": -85.14},
	{"name": "Evansville", "area": "IN", "lat": 37.97, "lon": -87.57},
	{"name": "South Bend", "area": "IN", "lat": 41.68, "lon": -86.25},
	{"name": "Bloomington", "area": "IN", "lat": 39.17, "lon": -86.53},
	{"name": "Des Moines", "area": "IA", "lat": 41.59, "lon": -93.62},
	{"name": "Cedar Rapids", "area": "IA", "lat": 41.98, "lon": -91.67},
	{"name": "Davenport", "area": "IA", "lat": 41.52, "lon": -90.58},
	{"name": "Iowa City", "area": "IA", "lat": 41.66, "lon": -91.53},
	{"name": "Sioux City", "area": "IA", "lat": 42.50, "lon": -96.40},
	{"name": "Wichita", "area": "KS", "lat": 37.69, "lon": -97.34},
	{"name": "Topeka", "area": "KS", "lat": 39.05, "lon": -95.68},
	{"name": "Overland Park", "area": "KS", "lat": 38.98, "lon": -94.67},
	{"name": "Lawrence", "area": "KS", "lat": 38.97, "lon": -95.24},
	{"name": "Lexington", "area": "KY", "lat": 38.04, "lon": -84.50},
	{"name": "Bowling Green", "area": "KY", "lat": 36.99, "lon": -86.44},
	{"name": "Owensboro", "area": "KY", "lat": 37.77, "lon": -87.11},
	{"name": "Baton Rouge", "area": "LA", "lat": 30.45, "lon": -91.15},
	{"name": "Shreveport", "area": "LA", "lat": 32.53, "lon": -93.75},
	{"name": "Lafayette", "area": "LA", "lat": 30.22, "lon": -92.02},
	{"name": "Lake Charles", "area": "LA", "lat": 30.23, "lon": -93.22},
	{"name": "Bangor", "area": "ME", "lat": 44.80, "lon": -68.77},
	{"name": "Lewiston", "area": "ME", "lat": 44.10, "lon": -70.21},
	{"name": "Biddeford", "area": "ME", "lat": 43.49, "lon": -70.45},
	{"name": "Annapolis", "area": "MD", "lat": 38.98, "lon": -76.49},
	{"name": "Frederick", "area": "MD", "lat": 39.41, "lon": -77.41},
	{"name": "Hagerstown", "area": "MD", "lat": 39.64, "lon": -77.72},
	{"name": "Worcester", "area": "MA", "lat": 42.26, "lon": -71.80},
	{"name": "Lowell", "area": "MA", "lat": 42.63, "lon": -71.32},
	{"name": "Cambridge", "area": "MA", "lat": 42.37, "lon": -71.11},
	{"name": "Plymouth", "area": "MA", "lat": 41.96, "lon": -70.67},
	{"name": "Grand Rapids", "area": "MI", "lat": 42.96, "lon": -85.67},
	{"name": "Lansing", "area": "MI", "lat": 42.73, "lon": -84.56},
	{"name": "Ann Arbor", "area": "MI", "lat": 42.28, "lon": -83.74},
	{"name": "Flint", "area": "MI", "lat": 43.01, "lon": -83.69},
	{"name": "Kalamazoo", "area": "MI", "lat": 42.29, "lon": -85.59},
	{"name": "Marquette", "area": "MI", "lat": 46.55, "lon": -87.40},
	{"name": "St. Paul", "area": "MN", "lat": 44.95, "lon": -93.09},
	{"name": "Duluth", "area": "MN", "lat": 46.79, "lon": -92.10},
	{"name": "St. Cloud", "area": "MN", "lat": 45.56, "lon": -94.16},
	{"name": "Mankato", "area": "MN", "lat": 44.16, "lon": -94.00},
	{"name": "Jackson", "area": "MS", "lat": 32.30, "lon": -90.18},
	{"name": "Gulfport", "area": "MS", "lat": 30.37, "lon": -89.09},
	{"name": "Hattiesburg", "area": "MS", "lat": 31.33, "lon": -89.29},
	{"name": "Tupelo", "area": "MS", "lat": 34.26, "lon": -88.70},
	{"name": "Springfield", "area": "MO", "lat": 37.21, "lon": -93.29},
	{"name": "Joplin", "area": "MO", "lat": 37.08, "lon": -94.51},
	{"name": "Jefferson City", "area": "MO", "lat": 38.58, "lon": -92.17},
	{"name": "Billings", "area": "MT", "lat": 45.78, "lon": -108.50},
	{"name": "Missoula", "area": "MT", "lat": 46.87, "lon": -113.99},
	{"name": "Great Falls", "area": "MT", "lat": 47.50, "lon": -111.30},
	{"name": "Bozeman", "area": "MT", "lat": 45.68, "lon": -111.04},
	{"name": "Helena", "area": "MT", "lat": 46.59, "lon": -112.04},
	{"name": "Lincoln", "area": "NE", "lat": 40.81, "lon": -96.70},
	{"name": "Grand Island", "area": "NE", "lat": 40.93, "lon": -98.34},
	{"name": "Kearney", "area": "NE", "lat": 40.70, "lon": -99.08},
	{"name": "Reno", "area": "NV", "lat": 39.53, "lon": -119.81},
	{"name": "Henderson", "area": "NV", "lat": 36.04, "lon": -114.98},
	{"name": "Carson City", "area": "NV", "lat": 39.16, "lon": -119.77},
	{"name": "Nashua", "area": "NH", "lat": 42.77, "lon": -71.47},
	{"name": "Concord", "area": "NH", "lat": 43.21, "lon": -71.54},
	{"name": "Portsmouth", "area": "NH", "lat": 43.07, "lon": -70.76},
	{"name": "Newark", "area": "NJ", "lat": 40.74, "lon": -74.17},
	{"name": "Jersey City", "area": "NJ", "lat": 40.73, "lon": -74.08},
	{"name": "Trenton", "area": "NJ", "lat": 40.22, "lon": -74.76},
	{"name": "Atlantic City", "area": "NJ", "lat": 39.36, "lon": -74.42},
	{"name": "Camden", "area": "NJ", "lat": 39.93, "lon": -75.12},
	{"name": "Santa Fe", "area": "NM", "lat": 35.69, "lon": -105.94},
	{"name": "Las Cruces", "area": "NM", "lat": 32.32, "lon": -106.76},
	{"name": "Roswell", "area": "NM", "lat": 33.39, "lon": -104.52},
	{"name": "Rochester", "area": "NY", "lat": 43.16, "lon": -77.61},
	{"name": "Syracuse", "area": "NY", "lat": 43.05, "lon": -76.15},
	{"name": "Albany", "area": "NY", "lat": 42.65, "lon": -73.76},
	{"name": "Ithaca", "area": "NY", "lat": 42.44, "lon": -76.50},
	{"name": "Yonkers", "area": "NY", "lat": 40.93, "lon": -73.90},
	{"name": "Greensboro", "area": "NC", "lat": 36.07, "lon": -79.79},
	{"name": "Durham", "area": "NC", "lat": 35.99, "lon": -78.90},
	{"name": "Winston-Salem", "area": "NC", "lat": 36.10, "lon": -80.24},
	{"name": "Asheville", "area": "NC", "lat": 35.60, "lon": -82.55},
	{"name": "Fargo", "area": "ND", "lat": 46.88, "lon": -96.79},
	{"name": "Bismarck", "area": "ND", "lat": 46.81, "lon": -100.78},
	{"name": "Grand Forks", "area": "ND", "lat": 47.93, "lon": -97.03},
	{"name": "Minot", "area": "ND", "lat": 48.23, "lon": -101.30},
	{"name": "Toledo", "area": "OH", "lat": 41.65, "lon": -83.54},
	{"name": "Akron", "area": "OH", "lat": 41.08, "lon": -81.52},
	{"name": "Dayton", "area": "OH", "lat": 39.76, "lon": -84.19},
	{"name": "Youngstown", "area": "OH", "lat": 41.10, "lon": -80.65},
	{"name": "Norman", "area": "OK", "lat": 35.22, "lon": -97.44},
	{"name": "Lawton", "area": "OK", "lat": 34.60, "lon": -98.39},
	{"name": "Stillwater", "area": "OK", "lat": 36.12, "lon": -97.06},
	{"name": "Salem", "area": "OR", "lat": 44.94, "lon": -123.04},
	{"name": "Eugene", "area": "OR", "lat": 44.05, "lon": -123.09},
	{"name": "Bend", "area": "OR", "lat": 44.06, "lon": -121.32},
	{"name": "Medford", "area": "OR", "lat": 42.33, "lon": -122.87},
	{"name": "Allentown", "area": "PA", "lat": 40.60, "lon": -75.49},
	{"name": "Erie", "area": "PA", "lat": 42.13, "lon": -80.09},
	{"name": "Harrisburg", "area": "PA", "lat": 40.27, "lon": -76.88},
	{"name": "Scranton", "area": "PA", "lat": 41.41, "lon": -75.66},
	{"name": "Lancaster", "area": "PA", "lat": 40.04, "lon": -76.31},
	{"name": "Providence", "area": "RI", "lat": 41.82, "lon": -71.41},
	{"name": "Warwick", "area": "RI", "lat": 41.70, "lon": -71.42},
	{"name": "Newport", "area": "RI", "lat": 41.49, "lon": -71.31},
	{"name": "Columbia", "area": "SC", "lat": 34.00, "lon": -81.03},
	{"name": "Charleston", "area": "SC", "lat": 32.78, "lon": -79.93},
	{"name": "Greenville", "area": "SC", "lat": 34.85, "lon": -82.39},
	{"name": "Myrtle Beach", "area": "SC", "lat": 33.69, "lon": -78.89},
	{"name": "Sioux Falls", "area": "SD", "lat": 43.54, "lon": -96.73},
	{"name": "Rapid City", "area": "SD", "lat": 44.08, "lon": -103.23},
	{"name": "Pierre", "area": "SD", "lat": 44.37, "lon": -100.35},
	{"name": "Brookings", "area": "SD", "lat": 44.31, "lon": -96.80},
	{"name": "Knoxville", "area": "TN", "lat": 35.96, "lon": -83.92},
	{"name": "Chattanooga", "area": "TN", "lat": 35.05, "lon": -85.31},
	{"name": "Clarksville", "area": "TN", "lat": 36.53, "lon": -87.36},
	{"name": "Lubbock", "area": "TX", "lat": 33.58, "lon": -101.86},
	{"name": "Provo", "area": "UT", "lat": 40.23, "lon": -111.66},
	{"name": "Ogden", "area": "UT", "lat": 41.22, "lon": -111.97},
	{"name": "St. George", "area": "UT", "lat": 37.10, "lon": -113.58},
	{"name": "Logan", "area": "UT", "lat": 41.74, "lon": -111.83},
	{"name": "Burlington", "area": "VT", "lat": 44.48, "lon": -73.21},
	{"name": "Montpelier", "area": "VT", "lat": 44.26, "lon": -72.58},
	{"name": "Rutland", "area": "VT", "lat": 43.61, "lon": -72.97},
	{"name": "Virginia Beach", "area": "VA", "lat": 36.85, "lon": -75.98},
	{"name": "Richmond", "area": "VA", "lat": 37.54, "lon": -77.44},
	{"name": "Norfolk", "area": "VA", "lat": 36.85, "lon": -76.29},
	{"name": "Roanoke", "area": "VA", "lat": 37.27, "lon": -79.94},
	{"name": "Arlington", "area": "VA", "lat": 38.88, "lon": -77.10},
	{"name": "Charlottesville", "area": "VA", "lat": 38.03, "lon": -78.48},
	{"name": "Spokane", "area": "WA", "lat": 47.66, "lon": -117.43},
	{"name": "Tacoma", "area": "WA", "lat": 47.25, "lon": -122.44},
	{"name": "Olympia", "area": "WA", "lat": 47.04, "lon": -122.90},
	{"name": "Bellingham", "area": "WA", "lat": 48.75, "lon": -122.48},
	{"name": "Yakima", "area": "WA", "lat": 46.60, "lon": -120.51},
	{"name": "Huntington", "area": "WV", "lat": 38.42, "lon": -82.45},
	{"name": "Morgantown", "area": "WV", "lat": 39.63, "lon": -79.96},
	{"name": "Wheeling", "area": "WV", "lat": 40.06, "lon": -80.72},
	{"name": "Parkersburg", "area": "WV", "lat": 39.27, "lon": -81.56},
	{"name": "Madison", "area": "WI", "lat": 43.07, "lon": -89.40},
	{"name": "Green Bay", "area": "WI", "lat": 44.52, "lon": -88.02},
	{"name": "Eau Claire", "area": "WI", "lat": 44.81, "lon": -91.50},
	{"name": "La Crosse", "area": "WI", "lat": 43.80, "lon": -91.24},
	{"name": "Cheyenne", "area": "WY", "lat": 41.14, "lon": -104.82},
	{"name": "Casper", "area": "WY", "lat": 42.87, "lon": -106.31},
	{"name": "Laramie", "area": "WY", "lat": 41.31, "lon": -105.59},
	{"name": "Sheridan", "area": "WY", "lat": 44.80, "lon": -106.96},
]


## ABROAD: the cities a North American invitational is held in or sends clubs
## from when they are not on the US map (Pete, 1 Oct: "something in
## Canada/Mexico/US"). Not a region anybody plays in; `find` knows them so the
## distances to them are real.
const ABROAD := [
	{"name": "Toronto", "area": "ON", "lat": 43.65, "lon": -79.38},
	{"name": "Montreal", "area": "QC", "lat": 45.50, "lon": -73.57},
	{"name": "Vancouver", "area": "BC", "lat": 49.28, "lon": -123.12},
	{"name": "Calgary", "area": "AB", "lat": 51.05, "lon": -114.07},
	{"name": "Ottawa", "area": "ON", "lat": 45.42, "lon": -75.70},
	{"name": "Edmonton", "area": "AB", "lat": 53.55, "lon": -113.49},
	{"name": "Winnipeg", "area": "MB", "lat": 49.90, "lon": -97.14},
	{"name": "Mexico City", "area": "CDMX", "lat": 19.43, "lon": -99.13},
	{"name": "Guadalajara", "area": "JAL", "lat": 20.66, "lon": -103.35},
	{"name": "Monterrey", "area": "NL", "lat": 25.69, "lon": -100.32},
	{"name": "Puebla", "area": "PUE", "lat": 19.04, "lon": -98.21},
	{"name": "Tijuana", "area": "BC", "lat": 32.51, "lon": -117.04},
]


static func table(region: int) -> Array:
	return EU if region == Region.EU else US + US_TOWNS


## The towns a generated rival club is named for: the big cities only.
static func league_names(region: int) -> Array[String]:
	var out: Array[String] = []
	for c in (EU if region == Region.EU else US):
		out.append(String(c["name"]))
	return out


static func names(region: int) -> Array[String]:
	var out: Array[String] = []
	for c in table(region):
		out.append(String(c["name"]))
	return out


## The row for a city name, searched in BOTH tables regardless of the region
## asked for. A save's region and a save's city have to agree, and if they ever
## do not, the honest answer is the city's real coordinates rather than nothing.
static func find(city: String) -> Dictionary:
	for r in [Region.US, Region.EU]:
		for c in table(r):
			if String(c["name"]) == city:
				return c
	for c in ABROAD:
		if String(c["name"]) == city:
			return c
	return {}


static func area_of(city: String) -> String:
	var c := find(city)
	return String(c.get("area", "")) if not c.is_empty() else ""


## "Detroit, MI" — the city as a person says it out loud.
static func full_name(city: String) -> String:
	var a := area_of(city)
	return city if a == "" else "%s, %s" % [city, a]


## HOW FAR APART TWO TOWNS ARE, in miles.
##
## Haversine on a sphere. The earth is not one and the error is about half a
## per cent at these distances, which is three orders of magnitude inside
## anything that reads this — the bands Homesick uses are hundreds of miles wide.
## Using the cheap formula and saying so beats using the expensive one and
## implying the answer is surveyed.
const EARTH_MILES: float = 3958.8


static func distance(a: String, b: String) -> float:
	if a == b:
		return 0.0
	var ca := find(a)
	var cb := find(b)
	if ca.is_empty() or cb.is_empty():
		return 0.0
	var la := deg_to_rad(float(ca["lat"]))
	var lb := deg_to_rad(float(cb["lat"]))
	var dlat := lb - la
	var dlon := deg_to_rad(float(cb["lon"]) - float(ca["lon"]))
	var h := sin(dlat * 0.5) * sin(dlat * 0.5) \
		+ cos(la) * cos(lb) * sin(dlon * 0.5) * sin(dlon * 0.5)
	return 2.0 * EARTH_MILES * asin(sqrt(clampf(h, 0.0, 1.0)))


## "210 miles" / "1,400 miles" — for the splash, where it is a fact about the
## afternoon rather than a figure anybody does arithmetic on.
static func distance_word(miles: float) -> String:
	if miles < 1.0:
		return UiKit.t("at home")
	var m := int(round(miles))
	if m < 1000:
		return UiKit.t("%d miles") % m
	return UiKit.t("%d,%03d miles") % [m / 1000, m % 1000]
