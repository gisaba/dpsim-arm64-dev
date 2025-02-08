# Fase di build
FROM debian:11-slim AS builder

ARG CIM_VERSION=CGMES_2.4.15_16FEB2016
ARG CIMPP_COMMIT=1b11d5c17bedf0ae042628b42ecb4e49df70b2f6
ARG VILLAS_VERSION=18cdd2a6364d05fbf413ca699616cd324abfcb54

ENV DEBIAN_FRONTEND=noninteractive

# Unione di tutti i comandi apt-get in un singolo layer
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        git \
        libconfig-dev \
        libcurl4-gnutls-dev \
        libeigen3-dev \
        libfmt-dev \
        libgraphviz-dev \
        libgsl-dev \ 
        libjansson-dev \
        libmosquitto-dev \
        libnl-3-dev \
        libprotobuf-dev \
        libprotoc-dev \
        libspdlog-dev \
        libssl-dev \
        libwebsockets-dev \
        pkg-config \
        protobuf-c-compiler \
        python3-dev \
        python3-pip \
        uuid-dev \
        wget && \
    rm -rf /var/lib/apt/lists/*

# Build sundials con ottimizzazioni
RUN cd /tmp && \
    git clone --branch v3.2.1 --depth 1 https://github.com/LLNL/sundials && \
    cd sundials && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_ARKODE=OFF -DBUILD_CVODE=OFF -DBUILD_IDA=OFF .. && \
    make -j$(nproc) install && \
    rm -rf /tmp/sundials

# Installazione efficiente libiec61850
RUN cd /tmp && \
    wget -q https://libiec61850.com/wp-content/uploads/2019/03/libiec61850-1.3.3.tar.gz && \
    tar -zxf libiec61850-1.3.3.tar.gz && \
    cd libiec61850-1.3.3 && \
    mkdir -p build && \  
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DBUILD_EXAMPLES=OFF .. && \
    make -j$(nproc) install && \
    rm -rf /tmp/libiec61850-1.3.3*  

# Build ottimizzata CIMpp
RUN cd /tmp && \
    apt-get update -y && apt-get install -y libxml2-dev && \
    git clone https://github.com/sogno-platform/libcimpp.git && \
    cd libcimpp && \
    git checkout ${CIMPP_COMMIT} && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake \
        -DLIBXML2_INCLUDE_DIR=/usr/include/libxml2 \
        -DLIBXML2_LIBRARIES=/usr/lib/aarch64-linux-gnu/libxml2.so \  
        -DBUILD_SHARED_LIBS=ON \
        -DUSE_CIM_VERSION=${CIM_VERSION} \
        .. && \
    make -j$(nproc) install && \
    rm -rf /tmp/libcimpp

	
# Build VILLASnode con ottimizzazioni
RUN cd /tmp && \
    # Installazione dipendenze mancanti
    apt-get install -y protobuf-compiler && \
    git clone https://github.com/VILLASframework/node.git villas-node && \
    cd villas-node && \
    git checkout ${VILLAS_VERSION} && \
    git submodule update --init --recursive && \
    mkdir -p build && cd build && \
    cmake \
        -DProtobuf_PROTOC_EXECUTABLE=/usr/bin/protoc \  
        -DDOWNLOAD_GO=OFF \
        -DENABLE_STATIC_LINKING=ON \
        .. && \
    make -j$(nproc) install && \
    rm -rf /tmp/villas-node

# Build DPSim
RUN git clone --depth 1 --branch v1.1.1 https://github.com/sogno-platform/dpsim.git /dpsim
WORKDIR /dpsim/build
RUN pip3 install --no-cache-dir -r ../requirements.txt numpy && \
    cmake .. && \
    make -j$(nproc) dpsimpy && \
    find . -name '*.so' -exec strip -s {} \;  

# Fase finale
FROM debian:11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LD_LIBRARY_PATH=/usr/local/lib \
    PYTHONPATH=/dpsim/build:/dpsim/python/src

# Installazione runtime dependencies (corretto libgsl25)
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        libcurl4 \
        libgsl25 \
        libjansson4 \
        libspdlog1 \
        libstdc++6 \
        python3 \
        python3-pip \
        python3-numpy \
        libgraphviz-dev \     
        graphviz \            
        libgvc6 \             
        libpathplan4 \        
        libxdot4  \    
		libgomp1 && \                        
    rm -rf /var/lib/apt/lists/*

# Copia soltanto gli artefatti necessari
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /dpsim /dpsim

WORKDIR /dpsim/jupyterlab
COPY ./examples ./examples

RUN pip3 install --no-cache-dir jupyterlab

EXPOSE 8888

CMD ["jupyter-lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]