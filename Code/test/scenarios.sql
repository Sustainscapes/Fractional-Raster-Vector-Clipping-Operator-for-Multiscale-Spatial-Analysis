----------- ########## Scenario Construction ######### ------------ 

CREATE TEMP TABLE test_raster (rast raster);
CREATE TEMP TABLE test_geom (id serial PRIMARY KEY, geom geometry);

-- 2. Generate the 5x5 Control Raster (Values 1 to 25)
INSERT INTO test_raster (rast)
SELECT
    ST_SetValues(
        ST_AddBand(
            ST_MakeEmptyRaster(5, 5, 0, 5, 1, -1, 0, 0, 3857),
            '32BF'::text, 0.0, NULL
        ),
        1, 1, 1,
        ARRAY[
            [ 1,  2,  3,  4,  5 ],
            [ 6,  7,  7,  9, 10 ], -- Note: Duplicate value '7' for variety
            [11, 12, 13, 14, 15 ],
            [16, 17, 18, 19, 20 ],
            [21, 22, 23, 24, 25 ]
        ]::double precision[]
    );

-- 3. Insert Test Geometries
INSERT INTO test_geom (geom) VALUES 
(ST_GeomFromText('POLYGON((1.0 4.0, 1.5 4.0, 1.5 3.0, 1.0 3.0, 1.0 4.0))', 3857)), -- #1: 50% Coverage
(ST_GeomFromText('POLYGON((2.0 4.0, 3.0 4.0, 3.0 3.0, 2.0 3.0, 2.0 4.0))', 3857)), -- #2: 100% Coverage
(ST_GeomFromText('POLYGON((1.5 3.5, 2.0 3.5, 2.0 3.0, 1.5 3.0, 1.5 3.5))', 3857)), -- #3: 25% Coverage
(ST_GeomFromText('POLYGON((1.0 3.0, 3.5 3.0, 3.5 1.0, 1.0 1.0, 1.0 3.0))', 3857)), -- #4: Multi-pixel span
(ST_GeomFromText('POLYGON((0.25 4.75, 0.75 4.75, 0.75 4.25, 0.25 4.25, 0.25 4.75))', 3857)); -- #5: Sub-pixel offset

---- Bigger Polygons
INSERT INTO test_geom (geom) VALUES 
(ST_GeomFromText('POLYGON((0.0 4.0, 3 4.0, 4 3, 4.5 2.5, 3 1, 0 1, 0 4))', 3857)); 

INSERT INTO test_geom (geom) VALUES 
(ST_GeomFromText('POLYGON((1 4.5, 4 4.5, 4.5 3.5, 4.25 2.25, 1 2.25, 1 4.5))', 3857)); 










----------------- Test location of boundary pixels Query ---------------------------------------


SELECT
    g.id AS geom_id,

    -- Global raster indices (original 5x5 grid)
    ST_WorldToRasterCoordX(tr.rast, ST_X(p.geom)) AS global_col,
    ST_WorldToRasterCoordY(tr.rast, ST_Y(p.geom)) AS global_row,

    -- Local clipped raster indices (for comparison)
    p.x AS local_col,
    p.y AS local_row,

    -- Original pixel value
    ST_Value(r.rast, 1, p.x, p.y) AS landcover_value,

    -- Fractional weight
    p.val AS fraction

FROM test_raster tr
JOIN test_geom g ON TRUE

CROSS JOIN LATERAL (
    SELECT raster_fractional_boundary_clip(tr.rast, g.geom, 0.0001) AS rast
) r

CROSS JOIN LATERAL
    ST_PixelAsPoints(r.rast, 2) AS p

WHERE
    p.val IS NOT NULL
    AND p.val > 0.0
    AND p.val < 1.0

ORDER BY g.id, global_row, global_col;




-------- Test the count of boundary pixels ------

WITH tile AS (
    SELECT
        tr.rast,
        tg.geom
    FROM test_raster tr
    JOIN test_geom tg
      ON tg.id = 7
)

SELECT
    COUNT(*) AS boundary_pixels
FROM (
    SELECT
        p.val
    FROM tile t
    CROSS JOIN LATERAL
        ST_PixelAsPoints(
            raster_fractional_clip_modela(t.rast, t.geom, 0.0),
            2
        ) p
    WHERE
        p.val IS NOT NULL
        AND p.val < 1.0   -- boundary condition
) s;








