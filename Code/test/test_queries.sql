----Test the count of boundary pixels on reel data ------

WITH muni AS (
    SELECT
        label_en AS municipality,
        ST_UnaryUnion(ST_Union(geom)) AS geom
    FROM dk_municipalities
    GROUP BY label_en
    HAVING label_en IN ('Skanderborg') -- 'Skanderborg'
),
tile AS (
    SELECT r.rast, m.geom
    FROM lu_agg_2021 r
    JOIN muni m
      ON ST_Intersects(r.tile_geom, m.geom)
    --- LIMIT 1
)
SELECT
    COUNT(*) AS boundary_pixels
FROM (
    SELECT
        p.val
    FROM tile t
    CROSS JOIN LATERAL
        ST_PixelAsPoints(
            raster_fractional_boundary_clip(t.rast, t.geom, 0.0),
            2
        ) p
    WHERE
        p.val IS NOT NULL
        AND p.val < 1.0   -- only boundary pixels
) s;



---------- Test the count of boundary pixels on reel data with resampling -----

WITH muni AS (
    SELECT
        label_en AS municipality,
        ST_UnaryUnion(ST_Union(geom)) AS geom
    FROM dk_municipalities
    GROUP BY label_en
    HAVING label_en IN ('Lolland')
),

tile AS (
    SELECT
        ST_Resample(
            r.rast,
            50.0,     -- new pixel width
            -50.0,    -- new pixel height (north-up)
            NULL,
            NULL,
            0,
            0,
            'NearestNeighbor'
        ) AS rast,
        m.geom
    FROM lu_agg_2021 r
    JOIN muni m
      ON ST_Intersects(r.tile_geom, m.geom)
    --LIMIT 1
)

SELECT
    COUNT(*) AS boundary_pixels
FROM (
    SELECT
        p.val
    FROM tile t
    CROSS JOIN LATERAL
        ST_PixelAsPoints(
            raster_fractional_boundary_clip(t.rast, t.geom, 0.0),
            2
        ) p
    WHERE
        p.val IS NOT NULL
        AND p.val < 1.0
) s;




----- test the number of bands ----------------

 SELECT DISTINCT
    ST_NumBands(rast) AS nb_bands
FROM (
    SELECT raster_fractional_boundary_clip(r.rast, m.geom) AS rast
    FROM lu_agg_2021 r
    JOIN dk_municipalities m
      ON m.label_en = 'Århus'
     AND ST_Intersects(r.tile_geom, m.geom)
) t;
