FROM ruby:3.2.1 as base

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' 11 > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && apt-get install -y \
  build-essential \
  nodejs \
  unzip \
  gnupg2 \
  libpq-dev \
  postgresql-client-11 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

ENV BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

WORKDIR /psd

RUN gem install bundler:2.3.26
COPY Gemfile* /psd/

RUN npm install --global yarn@1.22
COPY package.json /psd/
COPY yarn.lock /psd/

RUN bundle install --jobs=10
RUN yarn install --check-files && yarn cache clean

# production stage
FROM base AS runner

COPY . /psd

EXPOSE 3000
