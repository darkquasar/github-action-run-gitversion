# Container image that runs your code
FROM gittools/gitversion:5.7.1-ubuntu.20.04-x64-5.0

# Install JQ
RUN sudo apt update -qq \
    && sudo apt install -qqy --no-install-recommends jq \
    && apt-get -qy clean autoremove \
    && rm -rf /var/lib/apt/lists/*

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Ensure that the sh file can be executed
RUN ["chmod", "+x", "/entrypoint.sh"]

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
