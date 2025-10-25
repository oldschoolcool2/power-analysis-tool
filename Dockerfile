FROM rocker/shiny:4.4.0

USER root

# Install system dependencies for building R packages
# Only including dependencies actually needed by packages in renv.lock
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Install renv for package management
RUN R --quiet -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))" && \
    R -e "cat('renv installed at:', find.package('renv'), '\n')"

# Set working directory
WORKDIR /srv/shiny-server

# Copy renv configuration files FIRST (for Docker layer caching)
# This layer only rebuilds when dependencies change
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Create cache directory and restore packages
# This is the heavy operation that gets cached
# Explicitly load renv from system library before activating project
RUN mkdir -p /opt/renv/cache && \
    Rscript -e "library(renv, lib.loc = '/usr/local/lib/R/site-library'); renv::restore()"

# Configure renv runtime environment (after restore to avoid bootstrap conflicts)
ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE
ENV RENV_PATHS_LIBRARY=/usr/local/lib/R/site-library
ENV RENV_PATHS_CACHE=/opt/renv/cache

# Install TinyTeX for PDF generation (after renv restore)
RUN R --quiet -e "tinytex::install_tinytex()"

# Install LaTeX packages using R/tinytex (avoids PATH issues)
RUN R --quiet -e "tinytex::tlmgr_install(c('threeparttable', 'float', 'booktabs'))"

# Install code quality tools (lintr, styler, precommit)
# These are development dependencies, not in renv.lock
RUN R --quiet -e "install.packages(c('lintr', 'styler', 'precommit'), repos = 'https://cloud.r-project.org')"

# Create cache directory with proper permissions for shiny user
RUN mkdir -p /srv/shiny-server/app_cache && \
    chown -R shiny:shiny /srv/shiny-server/app_cache

# Copy application code LAST (changes most frequently)
# This layer rebuilds on every code change but uses cached dependencies
COPY --chown=shiny:shiny app.R app.R
COPY --chown=shiny:shiny analysis-report.Rmd analysis-report.Rmd
COPY --chown=shiny:shiny R/ R/
COPY --chown=shiny:shiny www/ www/
COPY --chown=shiny:shiny tests/ tests/

USER shiny

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]
