# Extending ERF + Noah-MP Coupling: Variable Requirements

## Background

The ERF + Noah-MP coupling requires two classes of variable exchanges to be completed:

1. SW radiation partitioning passed **ERF → Noah-MP** (currently hardcoded)
2. Surface-layer turbulence quantities passed **Noah-MP → ERF** (currently unexported)

---

## 1. SW Radiation Partitioning (ERF → Noah-MP)

### Problem

Noah-MP's `AtmosForcingMod.F90` decomposes total downward SW radiation (`SWDOWN`) into four components needed by the canopy model. It uses two ratio scalars — a direct/diffuse split and a visible/NIR split — to do so. ERF never populates these ratios, so Noah-MP silently falls back to hardcoded defaults.

The current driver (`NoahmpDriverMainMod.F90:71-72`) hardcodes:

```fortran
NoahmpIO%SWDDIR = NoahmpIO%SWDOWN * 0.7   ! 70% direct
NoahmpIO%SWDDIF = NoahmpIO%SWDOWN * 0.3   ! 30% diffuse
```

And `AtmosForcingMod.F90:81-82` applies defaults when the ratios are unset:

```
RadDirFrac = 0.7   ! direct beam fraction
RadVisFrac = 0.5   ! visible band fraction
```

### Variables Required from ERF

ERF's RRTMGP radiation solver produces per-band fluxes. The following must be exported and used to populate the two Noah-MP ratio fields:

| ERF Flux | Description |
|---|---|
| `SW_DN_Dir_Vis` | Direct downward SW, visible band [W m⁻²] |
| `SW_DN_Dir_Nir` | Direct downward SW, NIR band [W m⁻²] |
| `SW_DN_Dif_Vis` | Diffuse downward SW, visible band [W m⁻²] |
| `SW_DN_Dif_Nir` | Diffuse downward SW, NIR band [W m⁻²] |

### Noah-MP Variables to Populate

Defined in `drivers/erf/NoahmpIOVarType.F90:482-483`:

| Noah-MP Variable | Formula from ERF fluxes | Default (current) |
|---|---|---|
| `RadSwDirFrac` | `(SW_DN_Dir_Vis + SW_DN_Dir_Nir) / SWDOWN` | 0.7 |
| `RadSwVisFrac` | `(SW_DN_Dir_Vis + SW_DN_Dif_Vis) / SWDOWN` | 0.5 |

### Resulting Four-Component Decomposition

Once `RadSwDirFrac` and `RadSwVisFrac` are correctly set, `AtmosForcingMod.F90:81-100` computes:

| Component | Formula |
|---|---|
| Direct visible | `RadSwDirFrac × RadSwVisFrac × SWDOWN` |
| Direct NIR | `RadSwDirFrac × (1 − RadSwVisFrac) × SWDOWN` |
| Diffuse visible | `(1 − RadSwDirFrac) × RadSwVisFrac × SWDOWN` |
| Diffuse NIR | `(1 − RadSwDirFrac) × (1 − RadSwVisFrac) × SWDOWN` |

Note: all four components are zeroed when `CosSolarZenithAngle <= 0.0`.

### Impact

The partitioning into direct/diffuse and visible/NIR is critical for canopy radiation models. While the error in bulk SW forcing may be small (~10% direct/diffuse shift observed in test runs), using physically consistent ratios from RRTMGP is required for correctness and makes the coupling pathway consistent with how ERF's SLM coupling is handled.

---

## 2. Surface-Layer Turbulence (Noah-MP → ERF)

### Problem

Noah-MP computes Monin-Obukhov similarity theory (MOST) quantities internally but does not currently export them to ERF. These are needed by ERF's PBL schemes to use surface-layer stability information computed by the LSM.

### Variables to Export from Noah-MP

Defined in `src/EnergyVarType.F90:137-139`:

| Noah-MP Variable | Description | Units |
|---|---|---|
| `FrictionVelVeg` | Friction velocity, vegetated surface | m s⁻¹ |
| `FrictionVelBare` | Friction velocity, bare ground | m s⁻¹ |
| `MoLengthAbvCan` | Obukhov length, above zero-plane displacement (vegetated) | m |
| `MoLengthUndCan` | Obukhov length, below canopy | m |
| `MoLengthBare` | Obukhov length, bare ground | m |
| `MoStabParaAbvCan` | M-O stability parameter z/L, above canopy (vegetated) | — |
| `MoStabParaUndCan` | M-O stability parameter, below canopy | — |
| `MoStabParaBare` | M-O stability parameter, bare ground | — |

At minimum, `FrictionVelVeg` / `FrictionVelBare` and the above-canopy Obukhov length (`MoLengthAbvCan`) are needed for PBL coupling.

---

## Implementation Path

New variable bindings can be generated using the AI prompt templates maintained in both repositories:

- ERF side: `Source/LandSurfaceModel/Noah-MP/prompts/noahmpio_update.toml`
- Noah-MP driver side: `drivers/erf/prompts/noahmpio_update.toml`

The workflow for integrating changes:

1. Develop and test against `erf-model/noahmp` branch `v5.1.0.dev`
2. Open a PR targeting `v5.1.0.dev` (not `master` directly)
3. Once stable, create a PR from the ERF fork to NCAR/noahmp `develop`

---

## Code References

| File | Lines | Topic |
|---|---|---|
| `drivers/erf/NoahmpDriverMainMod.F90` | 71–72 | Hardcoded 70/30 SW split |
| `src/AtmosForcingMod.F90` | 81–100 | SW decomposition logic and defaults |
| `drivers/erf/NoahmpIOVarType.F90` | 482–483 | `RadSwDirFrac`, `RadSwVisFrac` declarations |
| `src/EnergyVarType.F90` | 137–139 | Friction velocity and Obukhov length declarations |
