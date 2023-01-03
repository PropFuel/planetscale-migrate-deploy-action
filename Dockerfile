FROM --platform=linux/amd64 ubuntu:22.04

# Build args
ARG PSCALE_VERSION=0.126.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq

# Download the pscale binary for the target platform
RUN curl -Lo pscale.deb https://github.com/planetscale/cli/releases/download/v${PSCALE_VERSION}/pscale_${PSCALE_VERSION}_linux_amd64.deb

# Install the pscale binary
RUN dpkg -i pscale.deb && rm pscale.deb

# Copy the entrypoint file
COPY entrypoint.sh /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
