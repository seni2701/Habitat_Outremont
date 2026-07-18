FROM rocker/geospatial:4.4.1

WORKDIR /projet

COPY analyse_arbres_outremont.R ./
COPY app.R ./
COPY data ./data

RUN mkdir -p outputs

CMD ["Rscript", "analyse_arbres_outremont.R"]
