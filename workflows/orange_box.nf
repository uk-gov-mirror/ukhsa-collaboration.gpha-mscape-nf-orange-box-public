#!/usr/bin/env nextflow

include { QC_SAMPLE }        from "../modules/qc_metrics.nf"
include { CLASPAR }          from "../modules/claspar.nf"
include { FASTQ_READ_STATS_AND_COLLATE } from "../modules/unclassified_readqc.nf"

include { PORTAL }           from "../modules/funnel_processes.nf"
include { PUBLISH_ONYX }     from "../modules/funnel_processes.nf"

include { ANALYSIS_FUNNEL as QC_FUNNEL }       from "./analysis_funnel.nf"
include { ANALYSIS_FUNNEL as VIRALIGN_FUNNEL } from "./analysis_funnel.nf"
include { ANALYSIS_FUNNEL as KRAKEN_FUNNEL }   from "./analysis_funnel.nf"
include { ANALYSIS_FUNNEL as SYLPH_FUNNEL }    from "./analysis_funnel.nf"
include { ANALYSIS_FUNNEL as UNCLASSIFIED_FUNNEL }    from "./analysis_funnel.nf"


workflow ORANGE_BOX {

    take:
    climb_id
    out_dir
    server
    bucket
    profiles_json
    taxaplease

    main:

    QC_SAMPLE(
        climb_id,
        out_dir,
        server
    )

    CLASPAR(
        climb_id,
        server,
        profiles_json,
        taxaplease
    )
    // how do we get the context into this module? 
    FASTQ_READ_STATS_AND_COLLATE(
        climb_id,
        server,
        out_dir,
        context
    )

    PORTAL(
        climb_id,
        QC_SAMPLE.out.analysis_json,
        CLASPAR.out.analysis_json_viralign,
        CLASPAR.out.analysis_json_kraken,
        CLASPAR.out.analysis_json_sylph,
        FASTQ_READ_STATS_AND_COLLATE.out.stats_summary
    )

    QC_FUNNEL(
        climb_id,
        "QC",
        QC_SAMPLE.out.analysis_json,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        QC_SAMPLE.out.upload_files
    )

    VIRALIGN_FUNNEL(
        climb_id,
        "CLASPAR_VA",
        CLASPAR.out.analysis_json_viralign,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        CLASPAR.out.upload_files_viralign
    )

    KRAKEN_FUNNEL(
        climb_id,
        "CLASPAR_KRAKEN",
        CLASPAR.out.analysis_json_kraken,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        CLASPAR.out.upload_files_kraken
    )

    SYLPH_FUNNEL(
        climb_id,
        "CLASPAR_SYLPH",
        CLASPAR.out.analysis_json_sylph,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        CLASPAR.out.upload_files_sylph
    )

    UNCLASSIFIED_FUNNEL(
        climb_id,
        "UNCLASSIFIED_READ_QC",
        FASTQ_READ_STATS_AND_COLLATE.out.stats_summary,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        FASTQ_READ_STATS_AND_COLLATE.out.upload_files
    )

    PUBLISH_ONYX(
        climb_id,
        server,
        QC_FUNNEL.out.analysis_id_file,
        VIRALIGN_FUNNEL.out.analysis_id_file,
        KRAKEN_FUNNEL.out.analysis_id_file,
        SYLPH_FUNNEL.out.analysis_id_file,
        UNCLASSIFIED_FUNNEL.out.analysis_id_file
    )

    emit:

    analysis_id_file =
        QC_FUNNEL.out.analysis_id_file

    funnel_logs =
        QC_FUNNEL.out.funnel_logs
            .mix(VIRALIGN_FUNNEL.out.funnel_logs)
            .mix(KRAKEN_FUNNEL.out.funnel_logs)
            .mix(SYLPH_FUNNEL.out.funnel_logs)
            .mix(UNCLASSIFIED_FUNNEL.out.funnel_logs)
            .mix(PUBLISH_ONYX.out.publish_logs)

}
