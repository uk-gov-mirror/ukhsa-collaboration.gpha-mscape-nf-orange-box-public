#!/usr/bin/env nextflow

include { QC_SAMPLE } from "../modules/qc_metrics.nf"

include { ANALYSIS_FUNNEL } from "../workflows/analysis_funnel.nf"

workflow QC_ANALYSIS {

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

workflow QC_FUNNEL {

    take:
    climb_id
    server
    bucket
    ready_to_go
    analysis_json
    upload_files

    main:

    ANALYSIS_FUNNEL(
        climb_id,
        "QC",
        analysis_json,
        server,
        bucket,
        ready_to_go,
        upload_files
    )

    emit:

    analysis_id_file =
        ANALYSIS_FUNNEL.out.analysis_id_file

    funnel_logs =
        ANALYSIS_FUNNEL.out.funnel_logs
}
