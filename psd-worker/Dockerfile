FROM ruby:2.5.5

WORKDIR /psd-web

COPY ./psd-web .

COPY ./psd-worker/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
