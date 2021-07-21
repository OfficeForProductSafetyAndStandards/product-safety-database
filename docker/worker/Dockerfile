FROM ruby:2.7.4

WORKDIR /psd

COPY ./docker/worker/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
