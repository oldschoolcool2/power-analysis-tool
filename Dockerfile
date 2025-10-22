FROM rocker/shiny:4.2.0

USER root

RUN R --quiet -e "install.packages(c('shinythemes', 'shinyBS', 'pwr', 'binom', 'kableExtra', 'rmarkdown', 'tinytex', 'powerSurvEpi', 'epiR'), quiet = TRUE)"

# Install TinyTeX for PDF generation
RUN R --quiet -e "tinytex::install_tinytex()"

# Install LaTeX packages
RUN tlmgr -repository http://mirror.ctan.org/systems/texlive/tlnet install threeparttable float booktabs

USER shiny

COPY --chown=shiny:shiny . /srv/shiny-server
