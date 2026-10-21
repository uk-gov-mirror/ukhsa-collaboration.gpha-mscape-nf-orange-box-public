#!/usr/bin/env nextflow

include { CLASPAR } from "../modules/claspar.nf"

include { ANALYSIS_FUNNEL as VIRALIGN_FUNNEL } from "../workflows/analysis_funnel.nf"
include { ANALYSIS_FUNNEL as KRAKEN_FUNNEL }   from "../workflows/analysis_funnel.nf"
include { ANALYSIS_FUNNEL as SYLPH_FUNNEL }    from "../workflows/analysis_funnel.nf"


workflow CLASPAR_ANALYSIS {

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


workflow CLASPAR_FUNNEL {

    take:
    climb_id
    server
    bucket
    ready_to_go

    analysis_json_viralign
    upload_files_viralign

    analysis_json_kraken
    upload_files_kraken

    analysis_json_sylph
    upload_files_sylph

    main:

    VIRALIGN_FUNNEL(
        climb_id,
        "CLASPAR_VA",
        analysis_json_viralign,
        server,
        bucket,
        ready_to_go,
        upload_files_viralign
    )

    KRAKEN_FUNNEL(
        climb_id,
        "CLASPAR_KRAKEN",
        analysis_json_kraken,
        server,
        bucket,
        ready_to_go,
        upload_files_kraken
    )

    SYLPH_FUNNEL(
        climb_id,
        "CLASPAR_SYLPH",
        analysis_json_sylph,
        server,
        bucket,
        ready_to_go,
        upload_files_sylph
    )

    emit:

    viralign_analysis_id =
        VIRALIGN_FUNNEL.out.analysis_id_file

    kraken_analysis_id =
        KRAKEN_FUNNEL.out.analysis_id_file

    sylph_analysis_id =
        SYLPH_FUNNEL.out.analysis_id_file

    funnel_logs =
        VIRALIGN_FUNNEL.out.funnel_logs
            .mix(KRAKEN_FUNNEL.out.funnel_logs)
            .mix(SYLPH_FUNNEL.out.funnel_logs)
}
