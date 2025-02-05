FROM debian:11-slim

ARG CIM_VERSION=CGMES_2.4.15_16FEB2016
ARG CIMPP_COMMIT=1b11d5c17bedf0ae042628b42ecb4e49df70b2f6
ARG VILLAS_VERSION=18cdd2a6364d05fbf413ca699616cd324abfcb54

ARG CMAKE_OPTS="-- -j 4"
ARG MAKE_OPTS=-j4
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update

# Toolchain
RUN apt-get -y install \
	build-essential \
	gcc g++ clang \
	git \
	make cmake pkg-config \
	python3-pip \
	wget \
	doxygen graphviz \
	gdb \
	python3-dev \
	libeigen3-dev \
	libxml2-dev \
	libgraphviz-dev \
	libgsl-dev \
	libspdlog-dev \
	pybind11-dev \
	libspdlog-dev \
	libfmt-dev 


# Build & Install sundials
RUN cd /tmp && \
	git clone --branch v3.2.1 --recurse-submodules --depth 1 https://github.com/LLNL/sundials.git && \
	mkdir -p sundials/build && cd sundials/build && \
	cmake ${CMAKE_OPTS} .. \
		-DCMAKE_BUILD_TYPE=Release && \
	make ${MAKE_OPTS} install

## Install minimal VILLASnode dependencies
RUN apt-get -y install \
	libssl-dev \
	uuid-dev \
	libcurl4-gnutls-dev \
	libjansson-dev \
	libwebsockets-dev

## Install optional VILLASnode dependencies
RUN apt-get -y install \
	libmosquitto-dev \
	libconfig-dev \
	libnl-3-dev \
	protobuf-compiler \
    libprotobuf-dev \
    libprotoc-dev \
    protobuf-c-compiler \
    libprotobuf-c-dev 

# Install libiec61850 from source
RUN cd /tmp && \
	wget https://libiec61850.com/wp-content/uploads/2019/03/libiec61850-1.3.3.tar.gz && \
	tar -zxvf libiec61850-1.3.3.tar.gz && rm libiec61850-1.3.3.tar.gz && \
	cd libiec61850-1.3.3 && \
	mkdir build && cd build && \
	cmake ${CMAKE_OPTS} .. \
		-DBUILD_SHARED_LIBS=ON && \
	make ${MAKE_OPTS} install && \
	rm -rf /tmp/libiec61850-1.3.3

## Install CIMpp from source
RUN cd /tmp && \
	git clone https://github.com/sogno-platform/libcimpp.git && \
	mkdir -p libcimpp/build && cd libcimpp/build && \
	git checkout ${CIMPP_COMMIT} && \
	git submodule update --init && \
	cmake ${CMAKE_OPTS} .. \
		-DBUILD_SHARED_LIBS=ON \
		-DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
		-DUSE_CIM_VERSION=${CIM_VERSION} \
		-DBUILD_ARABICA_EXAMPLES=OFF && \
	make ${MAKE_OPTS} install && \
	rm -rf /tmp/libcimpp



## Install VILLASnode from source
RUN cd /tmp && \
	git clone --recurse-submodules https://github.com/VILLASframework/node.git villas-node && \
	mkdir -p villas-node/build && cd villas-node/build && \
	git checkout ${VILLAS_VERSION} && \
	cmake ${CMAKE_OPTS} .. \
		-DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
		-DDOWNLOAD_GO=OFF && \
	make install && \
	rm -rf /tmp/villas-node


## Build DPSim Python module
RUN git clone https://github.com/sogno-platform/dpsim.git /dpsim
WORKDIR /dpsim
RUN git checkout tags/v1.1.1

RUN pip install -r requirements.txt 

RUN mkdir build && cd build

WORKDIR /dpsim/build

RUN cmake ${CMAKE_OPTS} ..
# RUN cmake ${CMAKE_OPTS} --build .
RUN cmake --build . --target dpsimpy

# required by dpsimpy 
RUN pip3 install numpy 

WORKDIR /dpsim

ARG CMAKE_OPTS=""

RUN python3 /dpsim/setup.py build_ext --inplace

ENV LD_LIBRARY_PATH=/usr/local/lib:/dpsim/build
ENV PYTHONPATH=$(pwd):$(pwd)/../python/src/:/usr/lib:/usr/local/lib 

COPY . /dpsim

# RUN if [ -f requirements.txt ]; then \
#     pip install --no-cache-dir -r requirements.txt; \
#     fi


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# # Imposta lo script come punto di ingresso
# ENTRYPOINT ["/entrypoint.sh"]

# Imposta il comando di default
CMD ["python3.9"]
