#!/bin/bash

function main() {
    set -e -x -o pipefail   # Output each line as executed, exit bash on error

    dx-download-all-inputs --parallel

    OUTDIR=/home/dnanexus/out
    AUTH_PROJ='project-FQqXfYQ0Z0gqx7XG9Z2b4K43'
    TOOLS_PROJ='project-ByfFPz00jy1fk6PjpZ95F27J'
    DOCKER_FILEID="$TOOLS_PROJ:file-GkGFVj00XBb45k0Y9QpjqB9p"
    DOCKER_FILENAME=$(dx describe $DOCKER_FILEID --name)


    echo "Making logfile outdir"
    LOGFILE_OUTDIR=${OUTDIR}/logfile/oncodeep_upload
    mkdir -p $LOGFILE_OUTDIR

    echo "Getting oncodeep_upload docker image"
    dx download $DOCKER_FILEID
    # --force-local required as if tarfile name contains a colon it tries to resolve the tarfile to a machine name
    DOCKER_IMAGENAME=$(tar xfO $DOCKER_FILENAME manifest.json --force-local | sed -E 's/.*"RepoTags":\["?([^"]*)"?.*/\1/')
    docker load < "$DOCKER_FILENAME"  # Load docker image
    sudo docker images

    if [[ $account_type ==  "Production" ]];  # Determine app running mode
        then
            echo "Production SFTP account selected as user input"
            CREDENTIALS_FILE="$AUTH_PROJ:oncodeep_credentials_production.json"
    elif [[ $account_type ==  "Validation" ]];
        then
            echo "Validation SFTP account selected as user input"
            CREDENTIALS_FILE="$AUTH_PROJ:oncodeep_credentials_validation.json"
    fi

    echo "Getting secrets"
    CREDENTIALS_FILENAME=$(dx describe $CREDENTIALS_FILE --name)

    dx download $CREDENTIALS_FILE
    ONCODEEP_HOSTNAME=$(jq -r '.hostname' $CREDENTIALS_FILENAME)
    ONCODEEP_USERNAME=$(jq -r '.username' $CREDENTIALS_FILENAME)
    ONCODEEP_PASSWORD=$(jq -r '.password' $CREDENTIALS_FILENAME)
    AUTH_TOKEN=$(dx cat $AUTH_PROJ:mokaguys_nexus_auth_key)

    echo "Creating output dir"
    mkdir -p $LOGFILE_OUTDIR  # Create output dir

    echo "Generating docker cmd"
    DOCKER_CMD="docker run --rm -v $file_to_upload_path:/oncodeep_upload/$file_to_upload_name -v $OUTDIR:/oncodeep_upload/outputs/ $DOCKER_IMAGENAME -R $run_identifier -F /oncodeep_upload/$file_to_upload_name -H $ONCODEEP_HOSTNAME -U $ONCODEEP_USERNAME -P $ONCODEEP_PASSWORD"
    echo "Running docker cmd"
    eval $DOCKER_CMD

    unset DX_WORKSPACE_ID
    
    dx cd $DX_PROJECT_CONTEXT_ID  # Set the project the worker will upload to

    echo "Moving outputs into output folders to delocalise into DNAnexus project"
    mv ${OUTDIR}/*.log $LOGFILE_OUTDIR

    dx-upload-all-outputs --parallel
}