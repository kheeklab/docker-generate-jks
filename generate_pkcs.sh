#!/bin/sh

# Check if KEYSTORE_PASSWORD is set in the environment
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "Error: Please set the KEYSTORE_PASSWORD environment variable."
    exit 1
fi

# Check if COMMON_NAMES is set in the environment when IMPORT_FROM_PEM is false
if [ "$IMPORT_FROM_PEM" != "true" ] && [ -z "$COMMON_NAMES" ]; then
    echo "Error: Please set the COMMON_NAMES environment variable with a list of comma-separated CN values."
    exit 1
fi

# Check if JKS_DIR is set in the environment
if [ -z "$JKS_DIR" ]; then
    echo "Error: Please set the JKS_DIR environment variable with the path to the directory where PKCS12 files will be generated."
    exit 1
fi

# Check if KEYSTORE_FILE is set in the environment
if [ -z "$KEYSTORE_FILE" ]; then
    echo "Error: Please set the KEYSTORE_FILE environment variable with the name of the PKCS12 file."
    exit 1
fi

# Check if IMPORT_FROM_PEM is set to true in the environment
if [ "$IMPORT_FROM_PEM" = "true" ]; then
    # Check if IMPORT_CERT_LIST is set in the environment
    if [ -z "$IMPORT_CERT_LIST" ]; then
        echo "Error: Please set the IMPORT_CERT_LIST environment variable with a list of comma-separated PEM files to import."
        exit 1
    fi
fi

# Variables
KEYSTORE_FILE_PATH="$JKS_DIR/$KEYSTORE_FILE"
TEMP_PEM_FILE="$JKS_DIR/all_certs.pem"

# Function to generate a certificate for a given CN
function generate_certificate() {
    local cn="$1"
    keytool -genkeypair -keyalg RSA -keysize 2048 -alias "$cn" -dname "CN=$cn, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=US" -keypass "$KEYSTORE_PASSWORD" -storetype PKCS12 -keystore "$KEYSTORE_FILE_PATH" -storepass "$KEYSTORE_PASSWORD" -validity 365
}

# Function to import certificates from PEM to the main PKCS12 file
function import_certificate() {
    local pem_file="$1"
    local cn=$(basename "$pem_file" | sed 's/_cert.pem$//')
    keytool -importcert -noprompt -alias "$cn" -file "$pem_file" -keystore "$KEYSTORE_FILE_PATH" -storetype PKCS12 -storepass "$KEYSTORE_PASSWORD"
}

# Create the JKS directory if it doesn't exist
mkdir -p "$JKS_DIR"

# Loop through the list of CN and generate certificates if IMPORT_FROM_PEM is false
if [ "$IMPORT_FROM_PEM" != "true" ]; then
    for cn in $(echo "$COMMON_NAMES" | tr ',' ' '); do
        generate_certificate "$cn"
    done
fi

# Import certificates from PEM files if IMPORT_FROM_PEM is true
if [ "$IMPORT_FROM_PEM" = "true" ]; then
    CERT_FILES=$(echo "$IMPORT_CERT_LIST" | tr ',' ' ')
    for pem_file in $CERT_FILES; do
        import_certificate "$pem_file"
    done
fi

echo "Certificates imported into $KEYSTORE_FILE_PATH successfully."
