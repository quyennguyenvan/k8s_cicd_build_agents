FROM ubuntu:22.04

ENV TARGETARCH="linux-x64"
# Also can be "linux-arm", "linux-arm64".

RUN apt update
RUN apt upgrade -y
RUN apt install -y curl git jq libicu70

# Install Java (OpenJDK 11) and Maven
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk maven && \
    apt-get clean

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Add JAVA_HOME to PATH
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify installations
RUN java -version && \
    mvn -version    

# Install python3 and pip3
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip
# Install pre-commit
RUN pip3 install pre-commit

# Install build dependencies, install azure-cli, and remove build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    libssl-dev \
    cargo \
    make && \
    pip3 install --no-cache-dir --prefer-binary azure-cli && \
    apt-get remove -y gcc musl-dev python3-dev libffi-dev libssl-dev cargo make && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install curl to download SonarQube Scanner
RUN apt-get update && \
    apt-get install -y curl unzip && \
    rm -rf /var/lib/apt/lists/*

ENV SONAR_SCANNER_VERSION=4.7.0.2747 \
    SONAR_SCANNER_HOME=/opt/sonar-scanner

# Download and install SonarQube Scanner
RUN curl -sSLo /tmp/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip && \
    unzip /tmp/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -d /opt && \
    mv /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux /opt/sonar-scanner && \
    rm /tmp/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip

# Add SonarQube Scanner to PATH
ENV PATH=${SONAR_SCANNER_HOME}/bin:${PATH}
ENV SONAR_SCANNER_OPTS="-server"

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

# Create agent user and set up home directory
RUN useradd -m -d /home/agent agent
RUN chown -R agent:agent /azp /home/agent

USER agent
# Another option is to run the agent as root.
# ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT [ "./start.sh" ]

