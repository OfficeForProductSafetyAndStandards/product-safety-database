FROM ruby:2.7.3

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

RUN apt-get update && apt-get install -y \
  build-essential \
  nodejs \
  unzip

WORKDIR /psd

RUN gem install bundler:2.2.21
COPY Gemfile /psd/
COPY Gemfile.lock /psd/

RUN npm install --global yarn@1.22
COPY package.json /psd/
COPY yarn.lock /psd/

COPY ./docker/web/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
