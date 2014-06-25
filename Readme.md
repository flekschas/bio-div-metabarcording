# Readme

## Introduction

This tool prepares READS coming from 454 and BLASTs them against a custom
database.

## Requirements

The tool runs on Linux and Mac and requires the following tools.

- [NCBI BLAST](http://blast.ncbi.nlm.nih.gov/) >= 2.2.29
- [SFF4FASTQ](https://github.com/indraniel/sff2fastq) >= 0.9.0
- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) => 0.32
- [FASTX-Toolkit](http://hannonlab.cshl.edu/fastx_toolkit/) => 0.0.14

## Installation / Set Up

Clone the repository to your favourite location, e.g. `/my/fav/location`:

`git clone https://bitbucket.org/flekschas/biodivex2 /my/fav/location`

The change the directory to `/my/fav/location`:

`cd /my/fav/location`

Make the main `run.bash` and all scripts contain in `scripts` executable:

`chmod +x ./run.bash`
`chmod +x scripts/*.bash`

Now you have to copy/move your `.SFF` of interest into the `data` folder.

Then copy/move your FASTA file that should become your BLAST DB into `blast`.

Next pleae copy/move your `barcodes.csv` and `primers.fasta` into `extras`. If
you are unsure about the format please take a look at `extras/Readme.md`.

Finally open `run.bash` with your favourite text editor and set the variables
in the *config* section according to your systems settings.

## Execution

After you have set up everything as explained above then your can run the
analysis by simple executing the `run.bash` script.

`./run.bash`