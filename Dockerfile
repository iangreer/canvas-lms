# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile`

ARG RUBY=2.6-p6.0.4

FROM instructure/ruby-passenger:$RUBY
LABEL maintainer="Instructure"

ARG POSTGRES_CLIENT=12
ENV APP_HOME /usr/src/app/
ENV RAILS_ENV development
ENV NGINX_MAX_UPLOAD_SIZE 10g
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ARG CANVAS_RAILS6_0=1
ENV CANVAS_RAILS6_0=${CANVAS_RAILS6_0}

ENV YARN_VERSION 1.19.1-1
ENV BUNDLER_VERSION 2.2.17
ENV GEM_HOME /home/docker/.gem/$RUBY
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG /home/docker/.bundle

WORKDIR $APP_HOME

USER root
COPY --chown=docker:docker . ${APP_HOME}

ARG USER_ID
# This step allows docker to write files to a host-mounted volume with the correct user permissions.
# Without it, some linux distributions are unable to write at all to the host mounted volume.
RUN if [ -n "$USER_ID" ]; then usermod -u "${USER_ID}" docker \
        && chown --from=9999 docker /usr/src/nginx /usr/src/app -R; fi

# When removing bionic/18.04/ruby 2.6 support remove the conditional package installs
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
  && printf 'path-exclude /usr/share/doc/*\npath-exclude /usr/share/man/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update -qq \
  && apt-get install -qqy --no-install-recommends \
       nodejs \
       yarn="$YARN_VERSION" \
       libxmlsec1-dev \
       python-lxml \
       libicu-dev \
       parallel \
       postgresql-client-$POSTGRES_CLIENT \
       unzip \
       pbzip2 \
       fontforge \
       autoconf \
       automake \
       gosu \
       git \
       build-essential \
  && ([ $(lsb_release -rs) = "18.04" ] || apt-get install -qqy --no-install-recommends \
       python2 \
       python-is-python2) \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0

# install pulsar stuff
ENV PULSAR_VERSION=2.6.1
ENV PULSAR_CLIENT_SHA512=90fdb6e3ad85c9204f2b20a9077684f667f84be32df0952f8823ccee501c9d64a4c8131cab38a295a4cb66e2b63211afcc24f32130ded47e9da8f334ec6053f5
ENV PULSAR_CLIENT_DEV_SHA512=d0cc58c0032cb35d4325769ab35018b5ed823bc9294d75edfb56e62a96861be4194d6546107af0d5f541a778cdc26274aac9cb7b5ced110521467f89696b2209
# pulsar installs 4 versions of this library, but we only need
# one, so at the end we remove the others to minimize the image size
RUN cd "$(mktemp -d)" && \
    curl -SLO 'http://archive.apache.org/dist/pulsar/pulsar-'$PULSAR_VERSION'/DEB/apache-pulsar-client.deb' && \
    curl -SLO 'http://archive.apache.org/dist/pulsar/pulsar-'$PULSAR_VERSION'/DEB/apache-pulsar-client-dev.deb' && \
    echo $PULSAR_CLIENT_SHA512 '*apache-pulsar-client.deb' | shasum -a 512 -c -s - && \
    echo $PULSAR_CLIENT_DEV_SHA512 '*apache-pulsar-client-dev.deb' | shasum -a 512 -c -s - && \
    apt install ./apache-pulsar-client*.deb && \
    rm ./apache-pulsar-client*.deb && \
    rm /usr/lib/libpulsarnossl.so* && \
    rm /usr/lib/libpulsar.a && \
    rm /usr/lib/libpulsarwithdeps.a

RUN if [ -e /var/lib/gems/$RUBY_MAJOR.0/gems/bundler-* ]; then BUNDLER_INSTALL="-i /var/lib/gems/$RUBY_MAJOR.0"; fi \
  && gem uninstall --all --ignore-dependencies --force $BUNDLER_INSTALL bundler \
  && gem install bundler --no-document -v $BUNDLER_VERSION \
  && find $GEM_HOME ! -user docker | xargs chown docker:docker

RUN npm install -g npm@latest && npm cache clean --force

USER docker

RUN set -eux; \
  \
  # set up bundle config options \
  bundle config --global build.nokogiri --use-system-libraries \
  && bundle config --global build.ffi --enable-system-libffi \
  && mkdir -p /home/docker/.bundle \
  && bundle install --jobs $(nproc)

RUN (yarn install --ignore-optional --pure-lockfile || yarn install --ignore-optional --pure-lockfile --network-concurrency 1)
RUN bundle exec rake canvas:compile_assets

USER root
COPY docker-entrypoint.sh /root/entrypoint.sh
