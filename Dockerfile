FROM ghcr.io/ptero-eggs/yolks:wine_latest

USER root

# Install dependencies including dbus and X11 utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        lsb-release \
        dbus \
        dbus-x11 \
        xvfb \
        x11-utils && \
    rm -rf /var/lib/apt/lists/*

# Setup Wine prefix and display
ENV WINEPREFIX=/home/container/.wine
ENV DISPLAY=:0
ENV XDG_RUNTIME_DIR=/tmp/runtime-container
RUN mkdir -p $WINEPREFIX $XDG_RUNTIME_DIR && \
    chmod 700 $XDG_RUNTIME_DIR

# Install Winetricks
RUN wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/sbin/winetricks

# Install Wine Mono
RUN wget -q -O /tmp/mono.msi https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi && \
    WINEDLLOVERRIDES="mscoree,mshtml=" wine msiexec /i /tmp/mono.msi /qn /quiet /norestart && \
    rm /tmp/mono.msi

# Setup virtual display and install .NET with proper dbus-daemon
RUN export DISPLAY=:0 && \
    export XDG_RUNTIME_DIR=/tmp/runtime-container && \
    Xvfb :0 -screen 0 1024x768x16 > /dev/null 2>&1 & \
    sleep 2 && \
    dbus-daemon --session --address=unix:path=/tmp/runtime-container/bus --nofork --nopidfile > /dev/null 2>&1 & \
    sleep 1 && \
    winetricks -q dotnet9 ; \
    pkill -f Xvfb ; \
    pkill -f dbus-daemon

# Install Python 3.10 in Wine
RUN export DISPLAY=:0 && \
    export XDG_RUNTIME_DIR=/tmp/runtime-container && \
    Xvfb :0 -screen 0 1024x768x16 > /dev/null 2>&1 & \
    sleep 2 && \
    dbus-daemon --session --address=unix:path=/tmp/runtime-container/bus --nofork --nopidfile > /dev/null 2>&1 & \
    sleep 1 && \
    winetricks -q python310 ; \
    pkill -f Xvfb ; \
    pkill -f dbus-daemon

# Install pip
RUN wine python -m ensurepip --upgrade && \
    wine python -m pip install --upgrade pip

# Create plugins directory
RUN mkdir -p /home/container/plugins/EndstoneRuntime

# Install levistone
RUN wine python -m pip install levistone --target /home/container/plugins/EndstoneRuntime

# Setup permissions
RUN chown -R container:container /home/container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
