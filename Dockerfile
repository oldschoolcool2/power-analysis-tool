FROM rocker/shiny:4.2.0

USER root

RUN R --quiet -e "install.packages(c('shinythemes', 'shinyBS', 'pwr', 'binom', 'kableExtra'), quiet = TRUE)"

# ctan.org went down when I tested this. The repository argument can be removed
RUN tlmgr -repository http://ctan.math.illinois.edu/systems/texlive/tlnet install threeparttable float booktabs

USER shiny

COPY --chown=shiny:shiny . /srv/shiny-server
