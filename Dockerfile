FROM rocker/shiny:4.4.0

USER root

# Install system dependencies for building R packages
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (combining both versions: rmarkdown from bug fix, bslib/renv from Tier 3)
RUN R --quiet -e "install.packages(c(\
    'bslib', \
    'shinyBS', \
    'pwr', \
    'binom', \
    'kableExtra', \
    'rmarkdown', \
    'tinytex', \
    'powerSurvEpi', \
    'epiR', \
    'renv' \
    ), repos='https://cloud.r-project.org/', quiet = TRUE)"

# Install TinyTeX for PDF generation
RUN R --quiet -e "tinytex::install_tinytex()"

# Install LaTeX packages using secure CTAN mirror
RUN tlmgr -repository https://mirror.ctan.org/systems/texlive/tlnet install threeparttable float booktabs

USER shiny

# Copy application files
COPY --chown=shiny:shiny . /srv/shiny-server

# Initialize renv if renv.lock exists
RUN if [ -f /srv/shiny-server/renv.lock ]; then \
    cd /srv/shiny-server && R --quiet -e "renv::restore()"; \
    fi
