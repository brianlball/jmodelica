FROM ubuntu:16.04
LABEL MAINTAINER Brian Ball <brian.ball@nrel.gov>

# build config vars
ARG IPOPT_VERSION="3.12.10"

# Set environment variables
ENV USER="root"
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
ENV JCC_JDK="/usr/lib/jvm/java-8-openjdk-amd64"
ENV IPOPT_HOME="/usr/local/Ipopt"
ENV JMODELICA_HOME="/usr/local/JModelica"
ENV MODELICAPATH="$JMODELICA_HOME/ThirdParty/MSL"
ENV PYTHONPATH="$PYTHONPATH:$JMODELICA_HOME/Python:$JMODELICA_HOME/Python/pymodelica:"
ENV SUNDIALS_HOME="$JMODELICA_HOME/ThirdParty/Sundials"
ENV LD_LIBRARY_PATH=:"$LD_LIBRARY_PATH:$IPOPT_HOME/lib/:$JMODELICA_HOME/ThirdParty/CasADi/lib:$SUNDIALS_HOME/lib"
ENV SEPARATE_PROCESS_JVM="$JAVA_HOME"

# add tmp and build dirs
RUN mkdir -p "/tmp" \
    && mkdir -p "/tmp/Ipopt" \
    && mkdir -p "/usr/local/" \
    && mkdir -p "/usr/local/Ipopt"

# Avoid warnings
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update \
	  && apt-get install -y \
    ant \
    build-essential \
    ca-certificates \
    cmake \
    cython \
    dc \
    default-jre-headless \
    jcc \
    git \
    g++ \
    gcc \
    gfortran \
    libpq-dev \
    liblapack-dev \
    libblas-dev \
    libboost-dev \
    make \
    patch \
    pkg-config \
    python-pip \
 	  python-jpype \
    python-numpy \
    python-scipy \
    python-lxml \
    python-nose \
    python-matplotlib \
    python2.7 \
    python2.7-dev \
    python-setuptools \
    python-software-properties \
    ssh \
    software-properties-common \
    swig \
    subversion \
    wget \
    vim \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# install python packages via pip
RUN pip install --upgrade pip
RUN pip install simulatortofmu tzwhere ipykernel jupyterlab
    
# Install jcc-3.0 to avoid error in python -c "import jcc"
#RUN pip install --upgrade pip
#RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/java-8-oracle && \
#    pip install --upgrade jcc

# wget and build Ipopt
RUN cd /tmp/Ipopt \
#    && wget http://www.coin-or.org/download/source/Ipopt/Ipopt-${IPOPT_VERSION}.tgz --no-check-certificate \
    && wget http://www.coin-or.org/download/source/Ipopt/Ipopt-${IPOPT_VERSION}.tgz \
    && tar xvf Ipopt-${IPOPT_VERSION}.tgz \
    && cd "/tmp/Ipopt/Ipopt-${IPOPT_VERSION}/ThirdParty/Blas" \
    && ./get.Blas \
    && cd "/tmp/Ipopt/Ipopt-${IPOPT_VERSION}/ThirdParty/Lapack" \
    && ./get.Lapack \
    && cd "/tmp/Ipopt/Ipopt-${IPOPT_VERSION}/ThirdParty/Mumps" \
    && ./get.Mumps \
    && cd "/tmp/Ipopt/Ipopt-${IPOPT_VERSION}/ThirdParty/Metis" \
    && ./get.Metis \
    && cd "/tmp/Ipopt/Ipopt-${IPOPT_VERSION}" \
    && ./configure --prefix="$BUILD_DIR/Ipopt" \
    && make -j$(nproc)\
    && make install

# build and install JModelica
RUN svn export https://svn.jmodelica.org/trunk "/tmp/JModelica" \
#    cd /tmp/JModelica/external && \
#    rm -rf /tmp/JModelica/external/Assimulo && \
#    svn export https://svn.jmodelica.org/assimulo/trunk Assimulo && \
    && cd "/tmp/JModelica" \
    && mkdir build \
    && cd build \
    && ../configure --prefix="/usr/local/JModelica" --with-ipopt="/usr/local/Ipopt" \
    && make -j$(nproc)\
    && make install \
    && make casadi_interface

# disable authentication for jupyter notebook server 
RUN mkdir "/root/.jupyter" \
    && touch /root/.jupyter/jupyter_notebook_config.py \
    && echo "c.NotebookApp.token = u''" >> ~/.jupyter/jupyter_notebook_config.py
    
# cleanup
RUN apt-get clean \
    && apt-get autoremove \
    && rm -rf /tmp/* /var/tmp/*

RUN python -c "import matplotlib.pyplot"