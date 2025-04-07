#!/bin/bash
license_project="$1"
source nextflow-bin/license/helper_funcs.sh
#refresh the token file
echo "Only download license once!"
download_license_token
