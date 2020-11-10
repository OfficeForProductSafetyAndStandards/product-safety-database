FROM ruby:2.7.2

WORKDIR /psd

COPY ./psd-web .

COPY ./docker/worker/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
