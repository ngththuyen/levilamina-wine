FROM ghcr.io/ptero-eggs/yolks:wine_latest

USER root

# Cài dependencies (đã có sẵn hầu hết trong image gốc)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        lsb-release && \
    rm -rf /var/lib/apt/lists/*

# Setup Wine prefix và display
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

# Setup virtual display TRƯỚC khi cài .NET
RUN export DISPLAY=:0 && \
    Xvfb :0 -screen 0 1024x768x16 & \
    sleep 2 && \
    winetricks -q dotnet9

# Cài Python 3.10 trong Wine
RUN export DISPLAY=:0 && \
    Xvfb :0 -screen 0 1024x768x16 & \
    sleep 2 && \
    winetricks -q python310

# Cài pip
RUN wine python -m ensurepip --upgrade && \
    wine python -m pip install --upgrade pip

# Tạo thư mục plugins
RUN mkdir -p /home/container/plugins/EndstoneRuntime

# Cài levistone
RUN wine python -m pip install levistone --target /home/container/plugins/EndstoneRuntime

# Setup quyền
RUN chown -R container:container /home/container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
