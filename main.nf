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
    ch_samples = Channel
    .fromPath(params.input, checkIfExists: true)
    .splitCsv(header: true, strip: true)

    ch_samples.view()
// [sample:S1, fastq_1:/data/S1_R1.fq.gz, fastq_2:/data/S1_R2.fq.gz, ...]
    //ORANGE_BOX(ch_climbids, params.outdir, params.server, params.bucket, params.profiles_json, params.taxaplease_db)
}
