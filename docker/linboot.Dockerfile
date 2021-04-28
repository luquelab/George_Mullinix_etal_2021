FROM mullinix/nvidia-cuda-devel-gcc-gsl

USER root

# download linboot source, compile, move executable
RUN mkdir -p /tmp/linboot && \
    mkdir -p /usr/local/bin && \
    cd /tmp/linboot && \
    git clone https://github.com/mullinix/cuda_linear_model_mc_bs.git && \
    cd cuda_linear_model_mc_bs && \
    make && \
    mv linboot /usr/local/bin/

# cleanup linboot source
RUN rm -rf /tmp/linboot

USER developer

CMD [ "linboot" ]
