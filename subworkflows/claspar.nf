#!/usr/bin/env nextflow

include { CLASPAR } from "../modules/claspar.nf"

workflow CLASPAR_WORKFLOW {

    take:
    climb_id
    server
    profiles_json
    taxaplease

    main:

    CLASPAR(
        climb_id,
        server,
        profiles_json,
        taxaplease
    )

    emit:

    analysis_json_viralign =
        CLASPAR.out.analysis_json_viralign

    analysis_json_kraken =
        CLASPAR.out.analysis_json_kraken

    analysis_json_sylph =
        CLASPAR.out.analysis_json_sylph

    upload_files_viralign =
        CLASPAR.out.upload_files_viralign

    upload_files_kraken =
        CLASPAR.out.upload_files_kraken

    upload_files_sylph =
        CLASPAR.out.upload_files_sylph
}
