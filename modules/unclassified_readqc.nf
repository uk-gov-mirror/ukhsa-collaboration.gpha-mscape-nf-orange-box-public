process FASTQ_READ_STATS {
    label "process_tiny"

    // change to the gpha-mscape-fastq-read-stats container
    container "community.wave.seqera.io/library/pyfastx_pip_pyfunctional_pytest:10dc317fc97efcc2"
    publishDir "${outdir}/${climb_id}", mode: 'copy'

    input:
    tuple val(climb_id), val(fastq_files)
    val outdir

    output:
    tuple val(climb_id), path("readQC_complete.txt"), path("*.stats"), emit: readQC

    script:
    def fastq1 = fastq_files[0]
    def fastq2 = fastq_files.size() > 1 ? fastq_files[1] : null

    """
    set +e

    if [ "${fastq2}" = "null" ] || [ -z "${fastq2}" ]; then
        fastq_read_stats.py "${fastq1}" > "${fastq1}.stats" 2> fastq_stdout_r1.txt
        status=\$?
    else
        fastq_read_stats.py "${fastq1}" > "${fastq1}.stats" 2> fastq_stdout_r1.txt
        fastq_read_stats.py "${fastq2}" > "${fastq2}.stats" 2> fastq_stdout_r2.txt
        status=\$?
    fi

    if [ \$status -eq 0 ]; then
        echo "True" > readQC_complete.txt
    else
        echo "False" > readQC_complete.txt
    fi
    """
}

process CREATE_READQC_ONYX_JSON {
    // change to the gpha-mscape-fastq-read-stats container
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:0.6.7'
    cpus 2
    memory '2GB'
    tag "${climb_id}"
    publishDir "${outdir}", mode: 'copy'

    input:
    tuple val(climb_id), val(readQC_status), path(csv)
    val server
    val context
    val outdir

    output:
    path("${climb_id}.unclassified_readQC.analysis_fields.json"), emit: stats_summary
    path "${climb_id}.unclassified.readQC.analysis_fields.log.txt", emit: logs
    path(csv) emit: upload_files

    script:
    """
    create_onyx_json.py \\
    --store-onyx \\
    -i ${climb_id} \\
    -s $server \\
    -c $context \\
    -o . \\
    -p "${workflow.manifest.name}, ${workflow.manifest.version}, ${workflow.manifest.homePage}" \\
    -f $csv \\
    -r $readQC_status \\
    """
}

workflow FASTQ_READ_STATS_AND_COLLATE {
    take:
    samples
    server
    outdir
    context

    main:
    ch_fastqs = samples
        .map { row ->
            def climb_id = row.climb_id
            def fastq1 = row.unclassified_reads_1
            def fastq2 = row.containsKey('unclassified_reads_2') ? row.unclassified_reads_2 : null

            if (fastq2) {
                tuple(climb_id, [fastq1, fastq2])
            } else {
                tuple(climb_id, [fastq1])
            }
        }

    stats_ch = FASTQ_READ_STATS(ch_fastqs, outdir).readQC

    normalized_readQC_complete = stats_ch
        .map { climb_id, readQC_file, stats_files ->
            def stats_list = (stats_files instanceof List) ? stats_files : [stats_files]
            def qc_text = readQC_file.text
            tuple(climb_id, qc_text, stats_list)
        }

    CREATE_READQC_ONYX_JSON(
        normalized_readQC_complete,
        server,
        context,
        outdir
    )

    emit:
    final_summary = CREATE_READQC_ONYX_JSON.out.stats_summary
}

workflow {
    FASTQ_READ_STATS_AND_COLLATE(
        samples,
        params.server,
        params.outdir,
        params.context
    )
}