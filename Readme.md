# Biodiversity and Evolution - Analyse biodiversity by metabarcoding using NGS data

## Introduction

Environmental Metagenomics: Metabarcoding and Microbes at Lake Gollin. This tool prepares READS coming from 454 and BLASTs them against a custom database.

**Presentation:**

[speakerdeck.com/flekschas/biodiversity-and-evolution-metabarcoding](https://speakerdeck.com/flekschas/biodiversity-and-evolution-metabarcoding)

## Requirements

The tool runs on Linux and Mac and requires the following tools.

- [NCBI BLAST](http://blast.ncbi.nlm.nih.gov/) >= 2.2.29
- [SFF4FASTQ](https://github.com/indraniel/sff2fastq) >= 0.9.0
- [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic) => 0.32
- [FASTX-Toolkit](http://hannonlab.cshl.edu/fastx_toolkit/) => 0.0.14

## Installation / Set Up

Clone the repository to your favourite location, e.g. `/my/fav/location`:

```
git clone https://github.com/flekschas/bio-div-metabarcording
```

The change the directory to `/my/fav/location`:

```
cd /my/fav/location
```

Make the main `run.bash` and all scripts contain in `scripts` executable:

```
chmod +x ./run.bash
chmod +x scripts/*.bash
```

Now you have to copy/move your `.SFF` of interest into the `data` folder.

Then copy/move your FASTA file that should become your BLAST DB into `blast`.

Next pleae copy/move your `barcodes.csv` and `primers.fasta` into `extras`. If
you are unsure about the format please take a look at `extras/Readme.md`.

Finally open `run.bash` with your favourite text editor and set the variables
in the *config* section according to your systems settings.

## Execution

After you have set up everything as explained above you can run the analysis
by simple executing `run.bash`.

```
./run.bash
```

## Visualise BLAST results

An easy way to visalise BLAST hits is to import them into [MEGAN](http://ab.inf.uni-tuebingen.de/software/megan/).
Make sure to specify the right taxonomy try via
`Edit > Preferences > Use alternative taxonomy` and loading the synonyms file
if you BLASTed against something other than NCBI. To generate a neat heat map
follow the steps:

1. Import BLAST hits into MEGAN.
2. After setting the LCA parameters select the leaves for which you want to generate a plot.
3. Export the plots as a DSV file using `taxa-name, counts` and `tab` separation.
4. Prepare the exported file using `scripts/prepare_megan_exports.bash`

### Authors

Fritz Lekschas, Annkatrin Bressin, Melanie Liedtke, Nina Kersten
