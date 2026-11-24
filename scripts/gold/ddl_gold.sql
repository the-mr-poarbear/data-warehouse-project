DROP VIEW IF EXISTS gold.attractions;
CREATE VIEW gold.attractions AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY po.osm_id) AS id,
    po.osm_id,
    po.name,
    po.way AS geom,

    CASE
        WHEN po.historic IS NOT NULL AND po.historic NOT IN ('yes', 'yes;used') THEN po.historic
		WHEN po.religion IS NOT NULL AND po.religion NOT IN ('none') THEN po.religion
        WHEN po.tourism IS NOT NULL AND  po.tourism NOT IN ('yes') THEN po.tourism
        ELSE 'n/a'
    END AS category
	
FROM silver.planet_osm_point AS po
WHERE po.historic IS NOT NULL OR 
	po.religion IS NOT NULL OR 
	(po.tourism IS NOT NULL AND 
	(po.tourism NOT IN (
        'motel',
        'hotel',
        'hostel',
        'guest_house'
    )));
	

DROP VIEW IF EXISTS gold.accommodations;
CREATE VIEW gold.accommodations AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY po.osm_id) AS id,
    po.osm_id,
    po.name,
    po.way AS geom,
    po.tourism AS category
	
FROM silver.planet_osm_point AS po
WHERE po.tourism IN (
        'motel',
        'information',
        'hotel',
        'hostel',
        'guest_house',
        'apartment'
    );


DROP VIEW IF EXISTS gold.residential_area;
CREATE VIEW gold.residential_area AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY po.osm_id) AS id,
    po.osm_id,
    po.name,
    po.way AS geom,
    po.place AS category
	
FROM silver.planet_osm_point AS po
WHERE po.place IN (
        'town',
        'village',
        'island',
        'city',
        'suburb'
    );


DROP VIEW IF EXISTS gold.services;
CREATE VIEW gold.services AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY po.osm_id) AS id,
    po.osm_id,
    po.name,
    po.way AS geom,
    po.amenity AS category
	
FROM silver.planet_osm_point AS po
WHERE po.amenity IN (
	'food_court',
	'cafe',
	'fast_food',
	'restaurant'
    );

DROP VIEW IF EXISTS gold.provinces;
CREATE VIEW gold.provinces AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY po.osm_id) AS id,
    po.osm_id,
    po.name,
    po.way AS geom

	
FROM silver.planet_osm_polygon AS po;

DROP VIEW IF EXISTS gold.ways;
CREATE VIEW gold.ways AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY li.osm_id) AS id,
    li.osm_id,
    li.name,
    li.way AS geom,

	CASE
        WHEN li.highway IS NOT NULL THEN 'highway'
		WHEN li.aerialway IS NOT NULL THEN 'aerialway'
        WHEN li.railway IS NOT NULL THEN 'railway'
		WHEN li.junction IS NOT NULL THEN 'junction'
		WHEN li.tunnel IS NOT NULL THEN 'tunnel'
        WHEN li.aeroway IS NOT NULL THEN 'aeroway'
        ELSE 'n/a'
    END AS category
	
FROM silver.planet_osm_line AS li
WHERE tunnel IS NOT NULL
	OR railway IS NOT NULL 
	OR junction IS NOT NULL 
	OR highway IS NOT NULL 
	OR aeroway IS NOT NULL 
	OR aerialway IS NOT NULL;

