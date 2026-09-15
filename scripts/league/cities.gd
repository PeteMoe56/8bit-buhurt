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
## COORDINATES ARE CITY-CENTRE, TO TWO DECIMALS. That is about a kilometre, which
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


static func table(region: int) -> Array:
	return EU if region == Region.EU else US


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
		return "at home"
	var m := int(round(miles))
	if m < 1000:
		return "%d miles" % m
	return "%d,%03d miles" % [m / 1000, m % 1000]
