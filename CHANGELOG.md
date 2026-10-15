# Changelog

[unreleased]v.1.0.0
neat first release
### Changes:
* Added devscape to the profiles
* Added devscape to the bin/orange_box_onyx_S3.py and orange_box_publish.py
* bumped claspar and QC versions.
* bumbed onyx analysis helper version to 0.6.7.
* changed funnel_processes to use new onyx analysis helper scripts
### Added:
* analysis_funnel subworkflow
### Fixed:



---
---
## v1.0.1-beta
Updated Claspar version.

### Changes:
* Claspar version and command
* param name from 'p'rofile_tables' to 'profiles_json'.

---
---

## v1.0.0-beta:
General tidy of the codebase. This is a working deployment.

### Changes:
* Removed 'fake claspar' in comments from testing.
* Tidied comments
* Changed the claspar container to recent version (v2.1.1).

---
---

## v1.0.0-alpha

Alpha release, preparing for production release of v1.0.0.

### Added:
- pipeline_trace file to the nextflow.config.


### Changes:
- removed unecessary config lines.
- after adding the orange box version, the json is written to a new file.
- updated to v0.6.0 of the onyx analysis helper.


---

March 2026 - ClasPar
ClasPar the classifier parser and taxa profiler has been added to the orange box.
ClasPar itself is run once, but creates three analyses (Kraken, Sylph and Viraligner), each of which are handled separately.
