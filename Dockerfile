# GeoServer DevDocker Environment
# Base image selection follows GeoServer/Docker pattern
# For GeoServer 2.28.x: tomcat:9.0-jdk21-temurin-noble
# For GeoServer 2.27.x: tomcat:9.0-jdk17-temurin-noble

ARG BASE_IMAGE=tomcat:9.0-jdk21-temurin-noble
FROM ${BASE_IMAGE}

# Install build tools and SSH server
RUN apt-get update && apt-get install -y \
    maven \
    ant \
    git \
    openssh-server \
    inotify-tools \
    curl \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Configure environment variables
ENV JAVA_HOME=/opt/java/openjdk
ENV MAVEN_HOME=/usr/share/maven
ENV PATH="${JAVA_HOME}/bin:${MAVEN_HOME}/bin:/root/bin:/root/.local/bin:/opt/devdocker/scripts:${PATH}"

# Configure SSH server
RUN mkdir /var/run/sshd && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Copy SSH configuration
COPY config/sshd_config /etc/ssh/sshd_config
RUN chmod 644 /etc/ssh/sshd_config

# Configure Maven
RUN mkdir -p /root/.m2/repository
COPY config/settings.xml.template /root/.m2/settings.xml
RUN chmod 644 /root/.m2/settings.xml

# Create workspace directories
RUN mkdir -p /workspace/geoserver \
    /workspace/geotools \
    /workspace/geowebcache \
    /opt/geoserver/data_dir \
    /opt/devdocker \
    /var/log/devdocker

# Copy scripts
COPY scripts/ /opt/devdocker/scripts/
RUN chmod +x /opt/devdocker/scripts/*.sh && \
    ln -s /opt/devdocker/scripts/*.sh /usr/local/bin/

# Expose ports
# 22: SSH for IDE connectivity
# 5005: JDWP debug port
# 8080: GeoServer web interface
# 8000: Documentation server (future)
EXPOSE 22 5005 8080 8000

# Set working directory
WORKDIR /workspace

# Configure root's shell to start in /workspace and add Git-aware prompt
RUN echo 'cd /workspace 2>/dev/null || true' >> /root/.bashrc && \
    echo '' >> /root/.bashrc && \
    echo '# Set Java environment for SSH sessions' >> /root/.bashrc && \
    echo 'export JAVA_HOME=/opt/java/openjdk' >> /root/.bashrc && \
    echo 'export PATH="${JAVA_HOME}/bin:${PATH}"' >> /root/.bashrc && \
    echo '' >> /root/.bashrc && \
    echo '# Git-aware prompt (similar to Git Bash)' >> /root/.bashrc && \
    echo 'parse_git_branch() {' >> /root/.bashrc && \
    echo '    local branch=$(git branch 2>/dev/null | grep "^\*" | sed "s/\* //" | sed "s/^/ (/" | sed "s/$/)/")' >> /root/.bashrc && \
    echo '    echo "$branch"' >> /root/.bashrc && \
    echo '}' >> /root/.bashrc && \
    echo 'parse_git_dirty() {' >> /root/.bashrc && \
    echo '    [[ $(git status --porcelain 2>/dev/null) ]] && echo "*"' >> /root/.bashrc && \
    echo '}' >> /root/.bashrc && \
    echo 'PS1="\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\[\e[33m\]\$(parse_git_branch)\$(parse_git_dirty)\[\e[0m\]\$ "' >> /root/.bashrc

# Copy entrypoint script
COPY entrypoint.sh /opt/devdocker/entrypoint.sh
RUN chmod +x /opt/devdocker/entrypoint.sh

ENTRYPOINT ["/opt/devdocker/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
