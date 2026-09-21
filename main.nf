#!/usr/bin/env nextflow

include { ORANGE_BOX } from "./workflows/orange_box"


workflow {
    if (params.samplesheet){
        samplesheet_ch = channel.fromPath(params.samplesheet)
    }
    else{
        exit(1, "Please specify a --samplesheet")
    }
    samplesheet_ch.view()
    //  split samplesheet CSV into channels
    samples = samplesheet_ch.splitCsv(header: true, quote: '\"')
        .map { row ->
            def climb_id = row.climb_id
            return climb_id
        }
        .set { ch_climbids }

    ORANGE_BOX(ch_climbids, params.outdir, params.server, params.bucket, params.profiles_json, params.taxaplease_db)
}
