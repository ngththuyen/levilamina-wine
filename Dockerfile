FROM ghcr.io/ptero-eggs/yolks:wine_latest

USER root

# Cài dependencies BAO GỒM xvfb-run
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        lsb-release \
        dbus \
        dbus-x11 \
        xvfb \
        x11-utils \
        wget \
        cabextract && \
    rm -rf /var/lib/apt/lists/*

# Setup Wine prefix
ENV WINEPREFIX=/home/container/.wine
ENV DISPLAY=:0
RUN mkdir -p $WINEPREFIX

# Cài Winetricks
RUN wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/sbin/winetricks

# Cài Wine Mono (không cần display)
RUN wget -q -O /tmp/mono.msi https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi && \
    WINEDLLOVERRIDES="mscoree,mshtml=" wine msiexec /i /tmp/mono.msi /qn /quiet /norestart && \
    rm /tmp/mono.msi

# Cài .NET 9 DÙNG xvfb-run (đảm bảo có display ảo)
RUN xvfb-run -a --server-args="-screen 0 1024x768x16" winetricks -q dotnet9

# Cài Python 3.10, pip, levistone
RUN xvfb-run -a --server-args="-screen 0 1024x768x16" winetricks -q python310 && \
    wine python -m ensurepip --upgrade && \
    wine python -m pip install --upgrade pip && \
    wine python -m pip install levistone --target /home/container/plugins/EndstoneRuntime

# Tạo plugins directory
RUN mkdir -p /home/container/plugins/EndstoneRuntime

# Setup quyền
RUN chown -R container:container /home/container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
