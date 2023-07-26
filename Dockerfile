FROM azul/zulu-openjdk-alpine:8

ENV KEYSTORE_PASSWORD="changeit" \
  IMPORT_FROM_PEM="false" \
  COMMON_NAMES="whoami, whoyouare" \
  IMPORT_CERT_LIST="" \
  JKS_DIR="/tmp" \
  KEYSTORE_FILE="mykeystore.p12"

# Copy the Bash script into the container
COPY generate_pkcs.sh /usr/local/bin/generate_pkcs.sh

# Set the script as the entrypoint
ENTRYPOINT ["sh", "/usr/local/bin/generate_pkcs.sh"]
