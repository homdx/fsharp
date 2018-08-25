FROM debian:stretch-slim
LABEL maintainer "Dave Curylo <dave@curylo.org>, Steve Desmond <steve@stevedesmond.ca>"

ENV MONO_THREADS_PER_CPU 50
# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.1.401
# Configure Kestrel web server to bind to port 80 when present
ENV ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps perfomance
NUGET_XMLDOC_MODE=skip

RUN MONO_VERSION=5.8.0.127 && \
    FSHARP_VERSION=10.0.2 && \
    FSHARP_BASENAME=fsharp-$FSHARP_VERSION && \
    FSHARP_ARCHIVE=$FSHARP_VERSION.tar.gz && \
    FSHARP_ARCHIVE_URL=https://github.com/fsharp/fsharp/archive/$FSHARP_VERSION.tar.gz && \
    export GNUPGHOME="$(mktemp -d)" && \
    apt-get update && apt-get --no-install-recommends install -y gnupg dirmngr && \
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/debian stretch/snapshots/$MONO_VERSION main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt-get install -y wget apt-transport-https && \
    apt-get update -y && \
    apt-get --no-install-recommends install -y pkg-config make nuget mono-devel msbuild ca-certificates-mono && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    printf "namespace a { class b { public static void Main(string[] args) { new System.Net.WebClient().DownloadFile(\"%s\", \"%s\");}}}" $FSHARP_ARCHIVE_URL $FSHARP_ARCHIVE > download-fsharp.cs && \
    mcs download-fsharp.cs && mono download-fsharp.exe && rm download-fsharp.exe download-fsharp.cs && \
    tar xf $FSHARP_ARCHIVE && \
    cd $FSHARP_BASENAME && \
    make && \
    make install && \
    cd ~ && \
    rm -rf /tmp/src /tmp/NuGetScratch ~/.nuget ~/.config ~/.local "$GNUPGHOME" && \
    echo apt-get purge -y make gnupg dirmngr && \
    echo apt-get clean && \
#From https://github.com/dotnet/dotnet-docker/blob/master/2.1/sdk/stretch/amd64/Dockerfile
# Install .NET CLI dependencies
apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
        curl \
    && echo rm -rf /var/lib/apt/lists/* \
&&  curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='639f9f68f225246d9cce798d72d011f65c7eda0d775914d1394df050bddf93e2886555f5eed85a75d6c72e9063a54d8aa053c64c326c683b94e9e0a0570e5654' \
    && sha512sum dotnet.tar.gz \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

WORKDIR /root
CMD ["fsharpi"]
