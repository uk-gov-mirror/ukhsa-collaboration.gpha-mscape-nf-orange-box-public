#!/usr/bin/env nextflow

include { QC_SAMPLE } from "../modules/qc_metrics.nf"

workflow QC_WORKFLOW {

    take:
    climb_id
    out_dir
    server

    main:

    QC_SAMPLE(
        climb_id,
        out_dir,
        server
    )

    emit:

    analysis_json =
        QC_SAMPLE.out.analysis_json

    upload_files =
        QC_SAMPLE.out.upload_files
}
