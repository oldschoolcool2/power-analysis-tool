FROM 833333815239.dkr.ecr.us-east-1.amazonaws.com/container-shiny:v1.1.0

USER root
RUN R --quiet -e "install.packages(c('shinythemes', 'pwr', 'binom', 'kableExtra', 'tinytex'), quiet = TRUE)"

# Install TinyTeX
RUN apt-get update -qq && apt-get install -y -qq wget
RUN curl -sL "https://yihui.name/gh/tinytex/tools/install-unx.sh" | sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && rm -rf /tmp/texlive

USER shiny

COPY --chown=shiny:shiny . /srv/shiny-server
# COPY . /srv/shiny-server

# ARG container_credentials
# ENV AWS_CONTAINER_CREDENTIALS_RELATIVE_URI $container_credentials

# RUN aws sts get-caller-identity

# RUN aws s3 sync --quiet s3://hcie-power-analysis-tool/refs /srv/shiny-server/www
