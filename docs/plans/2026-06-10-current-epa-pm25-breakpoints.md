# Current EPA PM2.5 Breakpoints

Status: Completed

## Goal

Return PM2.5 AQI scores and health categories using the current U.S. EPA
breakpoints instead of the superseded 2012 table.

## Source Of Truth

- EPA's February 2024 final AQI fact sheet states that the updated breakpoints
  became effective May 6, 2024:
  https://www.epa.gov/system/files/documents/2024-02/pm-naaqs-air-quality-index-fact-sheet.pdf
- EPA's current AQS breakpoint table confirms the concentration boundaries:
  https://aqs.epa.gov/aqsweb/documents/codetables/aqi_breakpoints.html

## Scope

- Replace the old PM2.5 branch ladder with a single data-driven breakpoint
  table: 0.0-9.0, 9.1-35.4, 35.5-55.4, 55.5-125.4, 125.5-225.4, and
  225.5-325.4 µg/m³.
- Cap concentrations above the AQI-500 boundary at 500 for the existing public
  response contract.
- Accept all finite nonnegative PM2.5 readings, including clean-air values
  below 5 µg/m³.
- Reject sensor coordinates outside latitude and longitude bounds.
- Increment the air-quality cache version so old-breakpoint scores cannot be
  returned after deployment.
- Cover every breakpoint edge, invalid concentration, sensor filtering, and
  cache version in runtime tests.

## Verification

- `make check`
- Mutation check: restoring the old 12.0 µg/m³ Good breakpoint causes boundary
  tests to fail.

## Outcome

The service now reports current EPA categories, treats low pollution as valid
data, and cannot reuse cached scores produced by the superseded calculation.
