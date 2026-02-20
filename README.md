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

---

## Conceptual Framework

For a raster pixel \( P_i \) and polygon \( G \), fractional inclusion is defined as:

\[
f(P_i, G) = \frac{\text{Area}(P_i \cap G)}{\text{Area}(P_i)}
\]

A threshold parameter \( \tau \in [0,1] \) controls inclusion:

- \( \tau = 0 \): fully fractional (reference model)
- \( \tau = 1 \): strict containment
- \( 0 < \tau < 1 \): minimum overlap requirement

The algorithm avoids evaluating full containment for all pixels by constructing an eroded geometry:

\[
G^{-} = \{ x \in G \mid \text{dist}(x, \partial G) \ge r \}
\]

Only pixels intersecting the boundary band require explicit overlap computation.

---

## Repository Structure
