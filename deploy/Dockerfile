# Dockerfile for Power Analysis Tool
# Based on rocker/r-ver for reproducibility

FROM rocker/r-ver:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    pandoc \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy renv files first for better caching
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Install renv and restore packages
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"
RUN R -e "renv::restore()"

# Copy the entire project
COPY . .

# Install the package
RUN R -e "remotes::install_local('.', dependencies = FALSE, upgrade = 'never')"

# Expose port
EXPOSE 3838

# Run the app
CMD ["R", "-e", "PowerAnalysisTool::run_app(options = list(host = '0.0.0.0', port = 3838))"]
