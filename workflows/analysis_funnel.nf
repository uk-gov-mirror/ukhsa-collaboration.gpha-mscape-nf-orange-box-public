#!/usr/bin/env nextflow

include { FIRST_ONYX_WRITE }  from "../modules/funnel_processes.nf"
include { S3_UPLOAD }         from "../modules/funnel_processes.nf"
include { FINAL_ONYX_UPDATE } from "../modules/funnel_processes.nf"

workflow ANALYSIS_FUNNEL {

    take:
    climb_id
    analysis_name
    analysis_json
    server
    bucket
    ready_to_go
    upload_files

    main:

    FIRST_ONYX_WRITE(
        climb_id,
        analysis_name,
        analysis_json,
        server,
        bucket,
        ready_to_go
    )

    S3_UPLOAD(
        climb_id,
        analysis_name,
        server,
        bucket,
        FIRST_ONYX_WRITE.out.temp_analysis_id_file,
        upload_files
    )

    FINAL_ONYX_UPDATE(
        climb_id,
        analysis_name,
        analysis_json,
        server,
        bucket,
        FIRST_ONYX_WRITE.out.temp_analysis_id_file,
        S3_UPLOAD.out.s3_location_json
    )

    emit:
    analysis_id_file = FINAL_ONYX_UPDATE.out.analysis_id_file

    funnel_logs = FIRST_ONYX_WRITE.out.funnel_logs
        .mix(S3_UPLOAD.out.funnel_logs)
        .mix(FINAL_ONYX_UPDATE.out.funnel_logs)
}
