# gpha-mscape-nf-orange-box
This repository contains helper functions that can be used to format
analyses ready for submission to onyx.

## Installation as standalone code

Clone repo:

`git clone git@github.com:ukhsa-collaboration/gpha-mscape-nf-orange-box-public.git`

## Use

To run the orange box you require a samplesheet, a text file with climb_id as a header and then the climb ids each in a new row.
The first time you run the orange box you will need to request the location of the following from the current lead of the mscape workgroup:
- the  devscape/mscape/synthscape token
- the name of the bucket
- the location of taxa please

Change your token for the relevant token you have obtained from the lead of the mscape group.

`git clone git@github.com:ukhsa-collaboration/gpha-mscape-nf-orange-box-public.git`

`nextflow run gpha-mscape-nf-orange-box-public/main.nf -profile climb,devscape --outdir <outdir> --samplesheet <samplesheet> --taxaplease_db <path_to_database> --profiles_json <path_to_profiles_json> --bucket <bucket> -e.ONYX_TOKEN=$ONYX_TOKEN`

## Add a new module

The Orange Box workflow is structured using Nextflow modules and subworkflows.
Analysis tools are implemented as individual modules, while publication of results to Onyx and S3 is handled through a shared ANALYSIS_FUNNEL subworkflow.
All analyses follow the same publication pathway:
FIRST_ONYX_WRITE -> S3_UPLOAD-> FINAL_ONYX_UPDATE
By using the shared `ANALYSIS_FUNNEL` workflow, new modules can be added without duplicating the publication logic.

1: Create the Module

Create a new module under modules/
    For example: modules/new_module.nf
    The module should take as input:
        -climb id or samplesheet
    The module should:
        - Run the underlying analysis tool.
        - Generate output files.
        - Generate an Onyx analysis metadata JSON file.
    Every Orange Box analysis module must emit:
        - analysis_json:  Analysis metadata for Onyx
        - upload_files: Files uploaded to S3
        - Optional (but encouraged) log_file

2: Import the Module

Add the module import to workflows/orange_box.nf:
    `include { NEW_MODULE } from "../modules/new_module.nf" `

3: Execute the Module

Within workflow ORANGE_BOX, add the module call:
    `NEW_MODULE( climb_id,server)`
   Adjust inputs as required by the module.

4: Update PORTAL Dependencies

`PORTAL` acts as a synchronisation point.
It ensures that all analysis modules have completed before any funnel processes begin.
    Add the new analysis JSON file as an input to the PORTAL process within modules/funnel_processes.nf:
    `path "${climb_id}.new_module.analysis_fields.json" `
Then update the PORTAL invocation in orange_box.nf:
     `PORTAL(climb_id,QC_SAMPLE.out.analysis_json,CLASPAR.out.analysis_json_viralign,CLASPAR.out.analysis_json_kraken,CLASPAR.out.analysis_json_sylph,NEW_MODULE.out.analysis_json)`

5: Create a Funnel Instance

Import an alias of the shared ANALYSIS_FUNNEL workflow:
    `include { ANALYSIS_FUNNEL as NEW_MODULE_FUNNEL } from "./analysis_funnel.nf" `
add a call within the workflow:
    `NEW_MODULE_FUNNEL(climb_id,"NEW_MODULE",NEW_MODULE.out.analysis_json,server,bucket,PORTAL.out.ready_to_go,NEW_MODULE.out.upload_files)`
Note: A workflow can only be called once per name within a workflow scope. Aliases allow the same subworkflow to be reused for multiple analyses:
    `include { ANALYSIS_FUNNEL as QC_FUNNEL } `
    `include { ANALYSIS_FUNNEL as VIRALIGN_FUNNEL } `
    `include { ANALYSIS_FUNNEL as KRAKEN_FUNNEL } `
    `include { ANALYSIS_FUNNEL as SYLPH_FUNNEL } `

6: Update PUBLISH_ONYX

Add the new analysis ID file to the `PUBLISH_ONYX` call:
`PUBLISH_ONYX(climb_id,server,QC_FUNNEL.out.analysis_id_file,VIRALIGN_FUNNEL.out.analysis_id_file,KRAKEN_FUNNEL.out.analysis_id_file,SYLPH_FUNNEL.out.analysis_id_file,NEW_MODULE_FUNNEL.out.analysis_id_file)`
You will also need to update the `PUBLISH_ONYX` process definition in: modules/funnel_processes.nf to accept the additional analysis ID file as an input. Similarly, update the `--analysis_id_files` argument passed to `orange_box_publish.py`.
