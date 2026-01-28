FROM rocker/r-ver:4.4.2
WORKDIR /app

RUN apt-get update && apt-get install -y \
    pkg-config \
    ca-certificates \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    zlib1g-dev \
    libsodium-dev \
    libxml2-dev \
    make \
    ghostscript \
    pandoc \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-lang-german \
	texlive-science \
    && rm -rf /var/lib/apt/lists/*


RUN R -e "options(repos=c(CRAN='https://cloud.r-project.org')); install.packages(c('plumber','xml2','stringr','magrittr'))"

COPY plumber.R /app/plumber.R
COPY make_letter.R /app/make_letter.R
COPY template /app/template

EXPOSE 8000
CMD ["R", "-e", "pr <- plumber::plumb('plumber.R'); pr$run(host='0.0.0.0', port=8000)"]