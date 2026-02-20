# Fractional Raster–Vector Clipping Operator

A database-native implementation of a **Fractional Raster–Vector Clipping Operator** for boundary-consistent and resolution-aware spatial aggregation.

This repository accompanies the paper:

> *A Fractional Raster–Vector Clipping Operator for Boundary-Consistent Multi-Scale Spatial Analysis*  
> Y. Hamdani, U.A. Treier, S. Normand

---

## Overview

Raster–vector clipping is a fundamental operation in geospatial analysis.  
Conventional implementations rely on binary inclusion rules (e.g., center-in-polygon or all-touched), which treat pixels as either fully inside or outside a target geometry. This discretization introduces **resolution-dependent boundary bias** during aggregation.

This repository provides:

- A formalized **fractional raster–vector clipping operator**
- A **PostgreSQL/PostGIS implementation**
- A boundary-localized algorithm that avoids universal containment tests
- Reproducible workflows for evaluating scale-dependent aggregation bias

The operator defines pixel contribution based on **proportional areal overlap**, enabling:

- Weighted aggregation
- Threshold-based categorical inclusion
- Resolution-consistent spatial analysis

---

## Key Features

- Formal mathematical definition of fractional overlap  
- Interior–boundary geometric decomposition using erosion  
- Efficient boundary-localized overlap computation  
- Dual-band raster output (thematic values + geometric weight)  
- Threshold-controlled inclusion semantics  
- Fully reproducible SQL workflows  




````markdown
## Installation

### Requirements

- PostgreSQL ≥ 13  
- PostGIS ≥ 3 (with raster support enabled)  
- A database with raster functionality activated  

You can verify PostGIS installation with:

```sql
SELECT PostGIS_Version();
````

---

### Installing the Function

1. Clone this repository:

```bash
git clone https://github.com/yourusername/fractional_polygon_raster_clip.git
cd Code
```

2. Connect to your PostgreSQL database and execute the SQL file containing the function:

```bash
psql -d your_database -f functions/raster_fractional_boundary_clip.sql
```

Alternatively, you may copy and execute the function definition directly inside `psql` or pgAdmin.

Once executed successfully, the function `raster_fractional_boundary_clip` will be available in your database.

---

## Usage

### Function Signature

```sql
raster_fractional_boundary_clip(
    rast      raster,
    geom      geometry,
    threshold double precision DEFAULT 0.0,
    at_least  boolean DEFAULT TRUE
)
```

### Parameters

* `rast` — Input raster
* `geom` — Polygon geometry used for clipping
* `threshold` — Minimum (or maximum) fractional overlap in the range ([0,1])
* `at_least` —

  * `TRUE`: keep pixels with fraction ≥ threshold
  * `FALSE`: keep pixels with fraction ≤ threshold

---

## Basic Use Cases

### 1. Fully Fractional Clipping (Reference Model)

Include all intersecting pixels and compute fractional weights:

```sql
SELECT raster_fractional_boundary_clip(rast, geom, 0.0, TRUE)
FROM raster_table, polygon_table
WHERE polygon_table.id = 1;
```

* All intersecting pixels are retained.
* Boundary pixels receive proportional weights.
* Fully contained pixels have weight = 1.

---

### 2. Threshold-Based Inclusion (e.g., 60% Overlap)

Retain only pixels with at least 60% overlap:

```sql
SELECT raster_fractional_boundary_clip(rast, geom, 0.6, TRUE)
FROM raster_table, polygon_table
WHERE polygon_table.id = 1;
```

* Pixels with overlap ≥ 0.6 are included.
* Fully contained pixels (fraction = 1) are always included.
* Pixels below threshold are excluded (set to NULL).

---

### 3. Strict Containment (Equivalent to τ = 1)

```sql
SELECT raster_fractional_boundary_clip(rast, geom, 1.0, TRUE)
FROM raster_table, polygon_table
WHERE polygon_table.id = 1;
```

Only fully contained pixels are retained.

---

## Output

The function returns a two-band raster:

* **Band 1** — Thematic raster values (clipped result)
* **Band 2** — Fractional overlap weights

Interior pixels have weight = 1.
Boundary pixels have weight ( 0 < f \leq 1 ).
Excluded pixels are set to NULL in both bands.

---

## Notes

* The geometry is automatically transformed to the raster SRID.
* Performance is optimized by restricting intersection computation to boundary pixels only.
* The function is `IMMUTABLE` and `PARALLEL SAFE`.

---