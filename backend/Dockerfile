ARG RUBY_VERSION=3.3.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Configure apt and install base packages
ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        build-essential \
        curl \
        default-mysql-client \
        libjemalloc2 \
        libvips \
        nodejs \
        npm && \
    npm install -g n && \
    n stable && \
    hash -r && \
    npm install -g npm@latest && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set environment
ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="" \
    DOCKERIZE_VERSION="v0.6.1"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        build-essential \
        default-libmysqlclient-dev \
        git \
        pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Set up executable permissions
RUN chmod +x /rails/bin/*

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Final stage for app image
# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
