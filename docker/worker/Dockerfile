FROM ruby:3.2.1

WORKDIR /psd

COPY ./docker/worker/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
