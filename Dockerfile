FROM rocker/shiny:4.4.0

USER root

# Install system dependencies for building R packages
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install renv for package management
ENV RENV_VERSION 1.0.7
RUN R --quiet -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))" && \
    R --quiet -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

# Set working directory
WORKDIR /srv/shiny-server

# Copy renv configuration files FIRST (for Docker layer caching)
# This layer only rebuilds when dependencies change
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Configure renv cache for container environment
ENV RENV_PATHS_LIBRARY renv/library
ENV RENV_PATHS_CACHE /opt/renv/cache

# Create cache directory and restore packages
# This is the heavy operation that gets cached
RUN mkdir -p /opt/renv/cache && \
    R --quiet -e "renv::restore()"

# Install TinyTeX for PDF generation (after renv restore)
RUN R --quiet -e "tinytex::install_tinytex()"

# Install LaTeX packages using secure CTAN mirror
RUN tlmgr -repository https://mirror.ctan.org/systems/texlive/tlnet install threeparttable float booktabs

# Copy application code LAST (changes most frequently)
# This layer rebuilds on every code change but uses cached dependencies
COPY --chown=shiny:shiny app.R app.R
COPY --chown=shiny:shiny analysis-report.Rmd analysis-report.Rmd
COPY --chown=shiny:shiny tests/ tests/

USER shiny

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]
