FROM ruby:2.5.5

WORKDIR /psd

COPY ./psd-web .

COPY ./docker/worker/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
