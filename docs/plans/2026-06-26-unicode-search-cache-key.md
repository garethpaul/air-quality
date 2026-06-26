# Unicode Search Cache Key Implementation Plan

Status: Completed

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Normalize canonically equivalent place-name queries before Mapbox lookup and Redis cache-key construction.

**Architecture:** Keep the boundary in `parse_search_query`, which already owns trimming, length, and control-character validation. Apply standard-library NFC normalization after trimming and before validation returns the query so both `GeoCode` construction and its `geocode_query_1_` key receive one canonical spelling.

**Tech Stack:** Python 3.12/3.14, `unicodedata`, `unittest`, Ruff, GNU Make.

---

### Task 1: Prove Canonical Query Equivalence

**Files:**
- Modify: `app_tests.py`

**Step 1: Write the failing test**

Add a regression asserting that `parse_search_query("  Cafe\u0301  ")` returns `"Caf\u00e9"` and that `search_payload` passes the NFC result to its geocoder factory.

**Step 2: Run test to verify it fails**

Run: `python3 -I -B -c 'import sys, unittest; sys.path.insert(0, "."); suite=unittest.defaultTestLoader.loadTestsFromNames(["app_tests.AppRouteHelperTest.test_parse_search_query_normalizes_canonical_unicode", "app_tests.AppRouteHelperTest.test_search_payload_uses_normalized_query"]); result=unittest.TextTestRunner(verbosity=2).run(suite); raise SystemExit(not result.wasSuccessful())'`

Expected: FAIL because the decomposed query is returned and forwarded unchanged.

### Task 2: Normalize At The Existing Boundary

**Files:**
- Modify: `app.py:63`
- Modify: `app_tests.py`

**Step 1: Write minimal implementation**

Change the trimmed assignment to `query_string = unicodedata.normalize("NFC", query.strip())` without changing the existing empty, length, or control-character policies.

**Step 2: Run focused tests**

Run: `python3 -I -B -c 'import sys, unittest; sys.path.insert(0, "."); suite=unittest.defaultTestLoader.loadTestsFromNames(["app_tests.AppRouteHelperTest.test_parse_search_query_normalizes_canonical_unicode", "app_tests.AppRouteHelperTest.test_search_payload_uses_normalized_query"]); result=unittest.TextTestRunner(verbosity=2).run(suite); raise SystemExit(not result.wasSuccessful())'`

Expected: PASS.

### Task 3: Preserve The Durable Contract

**Files:**
- Modify: `README.md`
- Modify: `SECURITY.md`
- Modify: `VISION.md`
- Modify: `scripts/check-baseline.sh`
- Modify: `CHANGES.md`
- Modify: `docs/plans/2026-06-26-unicode-search-cache-key.md`

**Step 1: Document the behavior**

State that canonically equivalent Unicode search text is normalized to NFC before Mapbox lookup and cache-key construction, while visible internationalized text remains supported.

**Step 2: Add mutation-sensitive contracts**

Require the normalization call, both regression names, synchronized guidance, and completed-plan evidence in `scripts/check-baseline.sh`.

**Step 3: Run complete verification**

Run: `/usr/bin/make check`

Expected: Ruff formatting/lint, audit, all unit tests, compilation, external-directory verification, and baseline contracts pass.

**Step 4: Commit**

Run: `git add app.py app_tests.py README.md SECURITY.md VISION.md scripts/check-baseline.sh CHANGES.md docs/plans/2026-06-26-unicode-search-cache-key.md && git commit -m "fix: normalize Unicode search cache keys"`

## Verification Completed

- The focused isolated regressions failed before implementation because
  decomposed `Café` was returned and forwarded unchanged, then passed after
  NFC normalization was added.
- Ruff format/lint, `pip-audit` with no known vulnerabilities, all 110 unit
  tests, and Python compilation passed with the isolated Python 3.14 toolchain.
- Seven isolated hostile mutations were rejected for missing normalization, NFD
  substitution, late normalization, missing parser coverage, missing forwarding
  coverage, removed public guidance, and stale plan status.
- Repository and external-directory `make check` passed Ruff format/lint,
  `pip-audit`, all 110 tests, Python compilation, Make authority checks,
  workflow checkout checks, and the portable baseline.
- The default pyenv `python` shim and the system Homebrew Python lacked the
  configured runtime or installed development tools; validation therefore used
  the existing isolated Python 3.14 environment.
