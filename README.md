# DNAnexus OncoDEEP Upload

This is the DNAnexus implementation of [oncodeep_upload v1.0.0](https://github.com/moka-guys/oncodeep_upload/releases/tag/v1.0.0). For further details on what the underlying script does and produces, please refer to that repository.

## Inputs

The app takes the following inputs:

* file_to_upload - File to be uploaded (e.g. a Fastq file or Masterdata File)
* run_identifier - Identifier for the run, for example OKD1234. Specifies the subfolder name on the SFTP server


## Outputs

The following outputs are produced:
* logfile - For audit trail

## How does this app work?

* This app runs a python scripts located inside a Docker image. 

## Developed by the Synnovis Genome Informatics Team
