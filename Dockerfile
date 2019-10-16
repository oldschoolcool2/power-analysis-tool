FROM 354388601783.dkr.ecr.eu-west-1.amazonaws.com/shiny:3.6.1-20191015

USER root

RUN R --quiet -e "install.packages(c('shinythemes', 'pwr', 'binom', 'kableExtra'), quiet = TRUE)"

# ctan.org went down when I tested this. The repository argument can be removed
RUN tlmgr -repository http://ctan.math.illinois.edu/systems/texlive/tlnet install threeparttable float booktabs

USER shiny

COPY --chown=shiny:shiny . /srv/shiny-server
