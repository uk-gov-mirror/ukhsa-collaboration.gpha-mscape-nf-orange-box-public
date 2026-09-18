#!/usr/bin/env nextflow

process CLASPAR {
    /*
	The process for running ClasPar.

        Inputs:
            - climb_id: Climb ID for a given sample
            - server: Where Onyx results should go i.e. synthscape or mscape.
            - outdir: (optional) Output dir - here given as . (work dir) and Nextflow will publish to params.outdir anyway.
            - profile_tables: path to excel spreadsheet which contains the taxa to profile mappings.
            - taxaplease: path to taxaplease database. If not provided, a new database will be created for each sample.

        Outputs:
            - 3 upload_files_* channels: for viral aligner, kraken-bacteria (this is a tuple of two files) and sylph results files to be uploaded to S3.
            - 3 analysis_json_* channels for viral_aligner, kraken-bacteria and sylph analyses to be added to Onyx.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-orangebox-claspar:v3.0.0'
    cpus 1
    memory '2GB'
    tag "${climb_id}"
    publishDir "$params.outdir/claspar", mode: "copy"

    input:
    val climb_id
    val server
    path profile_tables
    path taxaplease

    output:
    path "${climb_id}_viral_aligner_processed.csv", emit: upload_files_viralign
    tuple (path "${climb_id}_kraken_processed_genera.csv"), (path "${climb_id}_kraken_processed_species.csv"), emit: upload_files_kraken
    path "${climb_id}_sylph_processed.csv", emit: upload_files_sylph

    path "${climb_id}.claspar-viralaligner.analysis_fields.json", emit: analysis_json_viralign
    path "${climb_id}.claspar-krakenbacteria.analysis_fields.json", emit: analysis_json_kraken
    path "${climb_id}.claspar-sylph.analysis_fields.json", emit: analysis_json_sylph

    //path "${climb_id}_.*_claspar.log", emit: logs

    script:
    """
    echo "Running ClasPar..."
    claspar -i $climb_id -o . -s $server -p $profile_tables -d $taxaplease

    echo "Finished ClasPar."
    """
}
