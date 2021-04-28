FROM mullinix/nvidia-cuda-devel-gcc-gsl AS linboot

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

FROM rocker/verse AS rstudio

USER root

# this entrypoint script allows changing the port for Rstudio server
# just set the environment variable on launch, e.g. "-e RSTUDIO_PORT=9087"
COPY --from=linboot /usr/lib/x86_64-linux-gnu/*gsl* /usr/lib/x86_64-linux-gnu/
COPY --from=linboot /usr/local/bin/linboot /usr/local/bin/linboot
COPY rstudio.docker-entrypoint.sh /etc/rstudio/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/linboot
RUN chmod 755 /etc/rstudio/docker-entrypoint.sh
ENTRYPOINT ["/etc/rstudio/docker-entrypoint.sh"]

CMD ["/bin/bash"] 
