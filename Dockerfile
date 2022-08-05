FROM mcr.microsoft.com/vscode/devcontainers/universal:latest
LABEL maintainer="sysadmins@cs50.harvard.edu"

# Install Ruby packages
RUN gem install \
    bundler \
    jekyll \
    jekyll-theme-cs50 \
    minitest `# So that Bundler needn't install` \
    pygments.rb

# Install Node.js packages
RUN npm install -g http-server


# Patch http-server, until https://github.com/http-party/http-server/pull/811 is released
RUN sed -i "s/if (details.family === 'IPv4') {/if (details.family === 4) {/" /usr/local/lib/node_modules/http-server/bin/http-server


# Install SQLite 3.x
# https://www.sqlite.org/download.html
RUN cd /tmp && \
    wget https://www.sqlite.org/2022/sqlite-tools-linux-x86-3380500.zip && \
    unzip sqlite-tools-linux-x86-3380500.zip && \
    rm --force sqlite-tools-linux-x86-3380500.zip && \
    mv sqlite-tools-linux-x86-3380500/* /usr/local/bin/ && \
    rm --force --recursive sqlite-tools-linux-x86-3380500


# Install CS50 packages
RUN curl https://packagecloud.io/install/repositories/cs50/repo/script.deb.sh | bash && \
    apt update && \
    apt install --yes \
        libcs50


# Install Ubuntu packages
RUN apt update && \
    apt install --no-install-recommends --yes \
        astyle \
        bash-completion \
        clang \
        coreutils `# for fold` \
        dos2unix \
        dnsutils `# For nslookup` \
        fonts-noto-color-emoji `# For render50` \
        gdb \
        git \
        git-lfs \
        jq \
        less \
        make \
        man \
        man-db \
        nano \
        openssh-client `# For ssh-keygen` \
        psmisc `# For fuser` \
        sudo \
        valgrind \
        vim \
        weasyprint `# For render50` \
        zip


# Install Python packages
RUN apt update && \
    apt install --yes libmagic-dev `# For style50` && \
    pip3 install \
        awscli \
        "check50<4" \
        compare50 \
        cs50 \
        Flask \
        Flask-Session \
        help50 \
        pytest \
        render50 \
        s3cmd \
        style50 \
        "submit50<4"


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*


# Add user
RUN useradd --home-dir /home/ubuntu --shell /bin/bash ubuntu && \
    umask 0077 && \
    mkdir -p /home/ubuntu && \
    chown -R ubuntu:ubuntu /home/ubuntu


# Add user to sudoers
RUN echo "\n# CS50 CLI" >> /etc/sudoers && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "Defaults umask_override" >> /etc/sudoers && \
    echo "Defaults umask=0022" >> /etc/sudoers && \
    sed -e "s/^Defaults\tsecure_path=.*/Defaults\t!secure_path/" -i /etc/sudoers


# Version the image (and any descendants)
ARG VCS_REF
RUN echo "$VCS_REF" > /etc/issue
ONBUILD USER root
ONBUILD ARG VCS_REF
ONBUILD RUN echo "$VCS_REF" >> /etc/issue
ONBUILD USER ubuntu


# Set user
USER ubuntu
WORKDIR /home/ubuntu
ENV WORKDIR=/home/ubuntu

# End of cs50/cli

# Start of cs50/codespace

# Unset user
USER root


# Install glibc sources for debugger
# https://github.com/Microsoft/vscode-cpptools/issues/1123#issuecomment-335867997
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ focal main restricted" > /etc/apt/sources.list.d/_.list && \
    apt update && \
    cd /tmp && \
    apt source glibc && \
    rm --force /etc/apt/sources.list.d/_.list && \
    apt update && \
    mkdir --parents /build/glibc-sMfBJT && \
    mv glibc* /build/glibc-sMfBJT && \
    cd /build/glibc-sMfBJT \
    rm --force --recursive *.tar.xz \
    rm --force --recursive *.dsc


# Install window manager, X server, x11vnc (VNC server), noVNC (VNC client)
ENV DISPLAY=":0"
RUN apt install openbox xvfb x11vnc -y
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.zip -P/tmp && \
    unzip /tmp/v1.3.0.zip -d /tmp && \
    mv /tmp/noVNC-1.3.0 /opt/noVNC && \
    rm -rf /tmp/noVNC-1.3.0 && \
    chown -R ubuntu:ubuntu /opt/noVNC


# Install Ubuntu packages
RUN apt update && \
    apt install --no-install-recommends --yes \
        dwarfdump \
        jq \
        manpages-dev \
        pgloader \
        php-cli \
        php-mbstring \
        php-sqlite3


# For temporarily removing ACLs via opt/cs50/bin/postCreateCommand
# https://github.community/t/bug-umask-does-not-seem-to-be-respected/129638/9
RUN apt update && \
    apt install acl


# Temporary workaround for https://github.com/MicrosoftDocs/live-share/issues/4646
RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb && \
    dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb


# Invalidate caching for the remaining instructions
ARG VCS_REF


# Install VS Code extensions
RUN npm install -g vsce yarn && \
    mkdir --parents /opt/cs50/extensions && \
    cd /tmp && \
    git clone https://github.com/cs50/cs50.vsix.git && \
    cd cs50.vsix && \
    npm install && \
    vsce package && \
    mv cs50-0.0.1.vsix /opt/cs50/extensions && \
    pip3 install python-clients/cs50vsix-client/ && \
    cd /tmp && \
    rm --force --recursive cs50.vsix && \
    git clone https://github.com/cs50/phpliteadmin.vsix.git && \
    cd phpliteadmin.vsix && \
    npm install && \
    vsce package && \
    mv phpliteadmin-0.0.1.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive phpliteadmin.vsix && \
    git clone https://github.com/cs50/workspace-layout && \
    cd workspace-layout && \
    npm install && \
    vsce package && \
    mv workspace-layout-0.0.7.vsix /opt/cs50/extensions && \
    cd /tmp && \
    rm --force --recursive workspace-layout && \
    npm uninstall -g vsce yarn


# Copy files to image
COPY ./etc /etc
COPY ./opt /opt
RUN chmod a+rx /opt/cs50/bin/*
RUN chmod a+rx /opt/cs50/phpliteadmin/bin/phpliteadmin
RUN ln --symbolic /opt/cs50/phpliteadmin/bin/phpliteadmin /opt/cs50/bin/phpliteadmin


# Temporary workaround for https://github.com/cs50/code.cs50.io/issues/19
RUN echo "if [ -z \"\$_PROFILE_D\" ] ; then for i in /etc/profile.d/*.sh; do if ["$i" == "/etc/profile.d/debuginfod*"] ; then continue; fi; . \"\$i\"; done; export _PROFILE_D=1; fi"


# Temporary fix for https://github.com/microsoft/vscode-cpptools/issues/103#issuecomment-1151217772
RUN wget https://launchpad.net/ubuntu/+source/gdb/12.1-0ubuntu1/+build/23606376/+files/gdb_12.1-0ubuntu1_amd64.deb -P/tmp && \
    apt install /tmp/gdb_12.1-0ubuntu1_amd64.deb && \
    rm -rf /tmp/gdb_12.1-0ubuntu1_amd64.deb


# Set user
USER ubuntu
