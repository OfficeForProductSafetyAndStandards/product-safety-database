# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-bookworm as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    PSD_HOST_SUPPORT="support" \
    RAILS_ENV="production"

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libvips node-gyp pkg-config python-is-python3

# Install JavaScript dependencies
ARG NODE_VERSION=18.15.0
ARG YARN_VERSION=1.22.19
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Install application gems
COPY --link Gemfile Gemfile.lock ./
COPY prism/ prism/
COPY support_portal/ support_portal/
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install node modules
COPY --link .yarnrc package.json yarn.lock ./
COPY --link .yarn/releases/* .yarn/releases/
RUN yarn install --frozen-lockfile

# Copy application code
COPY --link . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE=DUMMY ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl imagemagick libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
ARG UID=1000 \
    GID=1000
RUN groupadd -f -g $GID rails && \
    useradd -u $UID -g $GID rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Deployment options
ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
