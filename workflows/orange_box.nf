#!/usr/bin/env nextflow

include { QC_SAMPLE }              from "../modules/qc_metrics.nf"
include { CLASPAR }                from "../modules/claspar.nf"
include { PORTAL }                 from "../modules/funnel_processes.nf"
include { FIRST_ONYX_WRITE }       from "../modules/funnel_processes.nf"
include { S3_UPLOAD }              from "../modules/funnel_processes.nf"
include { FINAL_ONYX_UPDATE }      from "../modules/funnel_processes.nf"
include { PUBLISH_ONYX }           from "../modules/funnel_processes.nf"


include { FIRST_ONYX_WRITE as FOW__CLASPAR_VIRALIGN }    from "../modules/funnel_processes.nf"
include { S3_UPLOAD as S3U__CLASPAR_VIRALIGN }           from "../modules/funnel_processes.nf"
include { FINAL_ONYX_UPDATE as FOU__CLASPAR_VIRALIGN }   from "../modules/funnel_processes.nf"

include { FIRST_ONYX_WRITE as FOW__CLASPAR_KRAKEN }      from "../modules/funnel_processes.nf"
include { S3_UPLOAD as S3U__CLASPAR_KRAKEN }             from "../modules/funnel_processes.nf"
include { FINAL_ONYX_UPDATE as FOU__CLASPAR_KRAKEN }     from "../modules/funnel_processes.nf"

include { FIRST_ONYX_WRITE as FOW__CLASPAR_SYLPH }       from "../modules/funnel_processes.nf"
include { S3_UPLOAD as S3U__CLASPAR_SYLPH }              from "../modules/funnel_processes.nf"
include { FINAL_ONYX_UPDATE as FOU__CLASPAR_SYLPH }      from "../modules/funnel_processes.nf"


workflow ORANGE_BOX {

    take:
    climb_id
    out_dir
    server
    bucket
    profiles_json
    taxaplease

    main:
    QC_SAMPLE(climb_id, out_dir, server)
    CLASPAR(climb_id, server, profiles_json, taxaplease)
    PORTAL(climb_id, QC_SAMPLE.out.analysis_json, CLASPAR.out.analysis_json_viralign, CLASPAR.out.analysis_json_kraken, CLASPAR.out.analysis_json_sylph)

    FIRST_ONYX_WRITE(climb_id, "QC", QC_SAMPLE.out.analysis_json, server, bucket, PORTAL.out.ready_to_go)
    S3_UPLOAD(climb_id, "QC", server, bucket, FIRST_ONYX_WRITE.out.temp_analysis_id_file, QC_SAMPLE.out.upload_files)
    FINAL_ONYX_UPDATE(climb_id, "QC", QC_SAMPLE.out.analysis_json, server, bucket, FIRST_ONYX_WRITE.out.temp_analysis_id_file, S3_UPLOAD.out.s3_location_json)


    // claspar funnel processes
    FOW__CLASPAR_VIRALIGN(climb_id, "CLASPAR_VA", CLASPAR.out.analysis_json_viralign, server, bucket, PORTAL.out.ready_to_go)
    S3U__CLASPAR_VIRALIGN(climb_id, "CLASPAR_VA", server, bucket, FOW__CLASPAR_VIRALIGN.out.temp_analysis_id_file, CLASPAR.out.upload_files_viralign)
    FOU__CLASPAR_VIRALIGN(climb_id, "CLASPAR_VA", CLASPAR.out.analysis_json_viralign, server, bucket, FOW__CLASPAR_VIRALIGN.out.temp_analysis_id_file, S3U__CLASPAR_VIRALIGN.out.s3_location_json)

    FOW__CLASPAR_KRAKEN(climb_id, "CLASPAR_KRAKEN", CLASPAR.out.analysis_json_kraken, server, bucket, PORTAL.out.ready_to_go)
    S3U__CLASPAR_KRAKEN(climb_id, "CLASPAR_KRAKEN", server, bucket, FOW__CLASPAR_KRAKEN.out.temp_analysis_id_file, CLASPAR.out.upload_files_kraken)
    FOU__CLASPAR_KRAKEN(climb_id, "CLASPAR_KRAKEN", CLASPAR.out.analysis_json_kraken, server, bucket, FOW__CLASPAR_KRAKEN.out.temp_analysis_id_file, S3U__CLASPAR_KRAKEN.out.s3_location_json)

    FOW__CLASPAR_SYLPH(climb_id, "CLASPAR_SYLPH", CLASPAR.out.analysis_json_sylph, server, bucket, PORTAL.out.ready_to_go)
    S3U__CLASPAR_SYLPH(climb_id, "CLASPAR_SYLPH", server, bucket, FOW__CLASPAR_SYLPH.out.temp_analysis_id_file, CLASPAR.out.upload_files_sylph)
    FOU__CLASPAR_SYLPH(climb_id, "CLASPAR_SYLPH", CLASPAR.out.analysis_json_sylph, server, bucket, FOW__CLASPAR_SYLPH.out.temp_analysis_id_file, S3U__CLASPAR_SYLPH.out.s3_location_json)
    // end of claspar funnel processes


    PUBLISH_ONYX(climb_id, server, FINAL_ONYX_UPDATE.out.analysis_id_file, FOU__CLASPAR_VIRALIGN.out.analysis_id_file, FOU__CLASPAR_KRAKEN.out.analysis_id_file, FOU__CLASPAR_SYLPH.out.analysis_id_file)

}
