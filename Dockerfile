FROM ghcr.io/ptero-eggs/yolks:wine_latest

USER root

# Cài dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        lsb-release \
        xvfb \
        cabextract \
        wget \
        unzip \
        curl \
        gnupg2 \
        software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# Cài WineHQ (đảm bảo có wine đầy đủ)
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    rm -rf /var/lib/apt/lists/*

# Setup Wine prefix
ENV WINEPREFIX=/home/container/.wine
ENV DISPLAY=:0
RUN mkdir -p $WINEPREFIX

# Cài Winetricks
RUN wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/sbin/winetricks

# Cài Wine Mono
RUN wget -q -O /tmp/mono.msi https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi && \
    WINEDLLOVERRIDES="mscoree,mshtml=" wine msiexec /i /tmp/mono.msi /qn /quiet /norestart && \
    rm /tmp/mono.msi

# Cài .NET 9
RUN winetricks -q dotnet9

# Cài Python 3.10 trong Wine
RUN winetricks -q python310

# Cài pip và upgrade
RUN wine python -m ensurepip --upgrade && \
    wine python -m pip install --upgrade pip

# Tạo thư mục plugins
RUN mkdir -p /home/container/plugins/EndstoneRuntime

# Cài levistone sẵn
RUN wine python -m pip install levistone --target /home/container/plugins/EndstoneRuntime

# Setup quyền
RUN chown -R container:container /home/container

# Quay lại user container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
