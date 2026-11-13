# gpha-mscape-nf-orange-box
This repository contains helper functions that can be used to format
analyses ready for submission to onyx.

## Installation as standalone code

Clone repo:

`git clone git@github.com:ukhsa-collaboration/gpha-mscape-nf-orange-box-public.git`

## Use

To run the Orange Box you require:
- a samplesheet - this is a simple text file with _climb_id_ as a header and then the sample id underneath, with multiple IDs across multiple rows (do not make a list of IDs in one row)
- the location of taxaplease database and the profiles json. These can usually be found in the `shared_resources`.

If you wish to run the orange box in full production mode and push to the Onyx database, you will need to request the location of the following from the current lead of the mscape workgroup:
- the devscape/mscape/synthscape token - Change your token for the relevant token you have obtained from the lead of the mscape group in your environment variables then pass these into the Nextflow command.
- the name of the bucket

_You can run the Orange Box without this; the modules should run to completion and create outputs, then errors will occur once trying to push to Onyx or S3 (by design). This is useful for adding and testing modules._

There is no installation, simply clone the repo and run the main.nf from the repo:

`git clone git@github.com:ukhsa-collaboration/gpha-mscape-nf-orange-box-public.git`

`nextflow run gpha-mscape-nf-orange-box-public/main.nf -profile climb,<*SCAPE> --outdir <outdir> --samplesheet <samplesheet> --taxaplease_db <path_to_database> --profiles_json <path_to_profiles_json> --bucket <bucket> -e.ONYX_TOKEN=$ONYX_TOKEN`

Or you can run directly from GitHub:

`nextflow run /ukhsa-collaboration/gpha-mscape-nf-orange-box-public -profile climb,<*SCAPE> --outdir <outdir> --samplesheet <samplesheet> --taxaplease_db <path_to_database> --profiles_json <path_to_profiles_json> --bucket <bucket> -e.ONYX_TOKEN=$ONYX_TOKEN`

## Add a new module

The Orange Box workflow is structured using Nextflow modules and subworkflows. Each analysis is implemented within its own subworkflow (for example `qc.nf` or `claspar.nf`), which is responsible for generating the analysis outputs required by the Orange Box pipeline. Publication of results to Onyx and S3 is handled through a shared ANALYSIS_FUNNEL subworkflow.

All analyses follow the same publication pathway:

`FIRST_ONYX_WRITE -> S3_UPLOAD-> FINAL_ONYX_UPDATE`

By using the shared `ANALYSIS_FUNNEL` workflow, new modules can be added without duplicating the publication logic.

### 1: Create the Module

Create a new module under `modules/` (for example: `modules/new_module.nf`)

The module should take as input:
- climb id
- output directory
_Adding additional inputs is possible, and will likely need adding as `params` in the config or passed through the samplesheet. This has upstream implications, so reach out to the team for help._

The module should:

- Run the underlying analysis tool.
- Generate output files.
- Generate an Onyx analysis metadata JSON file that matches the pattern `{climb_id}.{module}.analysis_fields.json`.

Every Orange Box analysis module must emit:

- analysis_json: Analysis metadata for Onyx that match the pattern `{climb_id}.{module}.analysis_fields.json`.
- upload_files: Files uploaded to S3
- Optional (but encouraged) log_file

### 2: Create a new subworkflow

Once a module has been created, it must be added to the Orange Box through an analysis-specific subworkflow.

Create a new file under subworkflows/new_subworkflow.nf

Add the module import to subworkflows/new_subworkflow.nf:

`include { NEW_MODULE } from "../modules/new_module.nf" `
`include { ANALYSIS_FUNNEL } from "../modules/analysis_funnel.nf" `

`workflow NEWMODULE_ANALYSIS {
    take:
    climb_id
    server `

`    main:
    NEWTHING( climb_id, server ) `

    emit:
    analysis_json = NEWMODULE.out.analysis_json
    upload_files = NEWMODULE.out.upload_files } `
`workflow NEWMODULE_FUNNEL {
    take:
        climb_id
        server
        bucket
        ready_to_go
        analysis_json upload_files
    main:
    ANALYSIS_FUNNEL(
        climb_id,
        "NEWMODULE",
        analysis_json,
        server,
        bucket,
        ready_to_go,
        upload_files )
    emit:
        analysis_id_file = ANALYSIS_FUNNEL.out.analysis_id_file
        funnel_logs = ANALYSIS_FUNNEL.out.funnel_logs }`

### 3: Import the subworkflow into the orange box

Within workflow ORANGE_BOX, add the subworkflow call:

`include { NEWMODULE_ANALYSIS } from "./subworkflows/newmodule.nf"
include { NEWMODULE_FUNNEL } from "./subworkflows/newmodule.nf"`

Add the analysis to the orange box, adjusting inputs as required.
`NEWMODULE_ANALYSIS(
    climb_id,
    server)`

### 4: Update PORTAL Dependencies

`PORTAL` acts as a synchronisation point.

It ensures that all analysis modules have completed before any funnel processes begin.
- Add the new analysis JSON file as an input to the PORTAL process within modules/funnel_processes.nf:

`path "${climb_id}.new_module.analysis_fields.json"`

Then update the PORTAL invocation in orange_box.nf:

`PORTAL(climb_id,QC_SAMPLE.out.analysis_json,CLASPAR.out.analysis_json_viralign,CLASPAR.out.analysis_json_kraken,CLASPAR.out.analysis_json_sylph,NEW_MODULE.out.analysis_json)`

### 5: Add the funnel to the workflow


`NEWMODULE_FUNNEL(
climb_id,
server,
bucket,
PORTAL.out.ready_to_go,
NEWMODULE_ANALYSIS.out.analysis_json,
NEWMODULE.out.upload_files)"`


### 6: Update PUBLISH_ONYX

Add the new analysis ID file to the `PUBLISH_ONYX` call and to the funnel_logs.

`PUBLISH_ONYX(climb_id,server,QC_FUNNEL.out.analysis_id_file,VIRALIGN_FUNNEL.out.analysis_id_file,KRAKEN_FUNNEL.out.analysis_id_file,SYLPH_FUNNEL.out.analysis_id_file,NEW_MODULE_FUNNEL.out.analysis_id_file)`

`funnel_logs=
    ...
    .mix(NEWMODULE_FUNNEL.out.funnel_logs)`

You will also need to update the `PUBLISH_ONYX` process definition in: modules/funnel_processes.nf to accept the additional analysis ID file as an input. Similarly, update the `--analysis_id_files` argument passed to `orange_box_publish.py`.
