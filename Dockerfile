FROM python:3.9

LABEL author="David Brawand" \
      description="MultiQC v1.11 with SEGLH plugin" \
      maintainer="dbrawand@nhs.net"

RUN git clone https://github.com/ewels/MultiQC.git --branch v1.11 && \
    cd MultiQC && \
    git checkout  && \
    python setup.py install

RUN git clone https://github.com/moka-guys/multiqc_plugins.git --branch main && \
    cd multiqc_plugins && \
    python setup.py install

RUN mkdir -p /data
WORKDIR /data

ENTRYPOINT [ "multiqc" ]
CMD [ "." ]
