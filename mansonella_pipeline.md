# Pipeline description and scripts used in Mansonella perstans and Mansonella ozzardi genome project (Sinha et al. 2023)

- The scripts described here were run on a SGE / Grid Engine via qsub. 
- All required software was installed using conda under various environments.

## Authors:
- Amit Sinha (New England Biolabs, Ipswich, MA, US)


1. Preprocessing of raw reads
### Key goals
- "Clumpify" : remove optical duplicates
- Removed bad tiles (e.g. in NextSeq data)
- Trim adapters
- Remove phiX sequences
- Remove stretches of poly-G (poly-C on read2) which are an artefact of NextSeq and similar platforms
- Remove reads from the human host
- Run FatsQC 
### Script(s) used :
- sh.00.preprocess-NextSeq-reads.sh


2. Metagenomic assembly using Spades
### Script(s) used :
- sh.01.metaspades.sh






## Assessing genome completeness using BUSCO


### Running BUSCO for genome assemblies of Cj and other filarial nematodes




### Orthology analysis using OrthoFinder




******
## License
Licensed as GNU General Public License v3.0. See LICENSE file in the root directory of this source tree.
[![License](https://img.shields.io/github/license/aWormGuy/Mansonella-Genomes-Sinha-et-al.-2023)](https://opensource.org/license/gpl-3-0/)
