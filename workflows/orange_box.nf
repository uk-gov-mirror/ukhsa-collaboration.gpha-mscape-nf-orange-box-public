include { QC_ANALYSIS }      from "../subworkflows/qc.nf"
include { QC_FUNNEL }        from "../subworkflows/qc.nf"

include { CLASPAR_ANALYSIS } from "../subworkflows/claspar.nf"
include { CLASPAR_FUNNEL }   from "../subworkflows/claspar.nf"

include { PORTAL }           from "../modules/funnel_processes.nf"
include { PUBLISH_ONYX }     from "../modules/funnel_processes.nf"

workflow ORANGE_BOX {

    take:
    climb_id
    out_dir
    server
    bucket
    profiles_json
    taxaplease

    main:

    QC_ANALYSIS(
        climb_id,
        out_dir,
        server
    )

    CLASPAR_ANALYSIS(
        climb_id,
        server,
        profiles_json,
        taxaplease
    )

    PORTAL(
        climb_id,
        QC_ANALYSIS.out.analysis_json,
        CLASPAR_ANALYSIS.out.analysis_json_viralign,
        CLASPAR_ANALYSIS.out.analysis_json_kraken,
        CLASPAR_ANALYSIS.out.analysis_json_sylph
    )

    QC_FUNNEL(
        climb_id,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        QC_ANALYSIS.out.analysis_json,
        QC_ANALYSIS.out.upload_files
    )

    CLASPAR_FUNNEL(
        climb_id,
        server,
        bucket,
        PORTAL.out.ready_to_go,

        CLASPAR_ANALYSIS.out.analysis_json_viralign,
        CLASPAR_ANALYSIS.out.upload_files_viralign,

        CLASPAR_ANALYSIS.out.analysis_json_kraken,
        CLASPAR_ANALYSIS.out.upload_files_kraken,

        CLASPAR_ANALYSIS.out.analysis_json_sylph,
        CLASPAR_ANALYSIS.out.upload_files_sylph
    )

    PUBLISH_ONYX(
        climb_id,
        server,
        QC_FUNNEL.out.analysis_id_file,
        CLASPAR_FUNNEL.out.viralign_analysis_id,
        CLASPAR_FUNNEL.out.kraken_analysis_id,
        CLASPAR_FUNNEL.out.sylph_analysis_id
    )

    emit:

    analysis_id_file =
        QC_FUNNEL.out.analysis_id_file

    funnel_logs =
        QC_FUNNEL.out.funnel_logs
            .mix(CLASPAR_FUNNEL.out.funnel_logs)
            .mix(PUBLISH_ONYX.out.publish_logs)
}
