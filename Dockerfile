FROM php:7.2-fpm-alpine

COPY etc  /usr/local/etc

##ENV ALPINE_VERSION=3.8

#### packages from https://pkgs.alpinelinux.org/packages
# These are always installed. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * bash: For entrypoint, and debugging
ENV PACKAGES="\
  bash vim tini \
  m4 \
  autoconf \
"

# These packages are not installed immediately, but are added at runtime or ONBUILD to shrink the image as much as possible. Notes:
#   * build-base: used so we include the basic development packages (gcc)
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
ENV BUILD_PACKAGES="\
  build-base \
  libpng-dev freetype-dev libjpeg-turbo-dev \
#  linux-headers \
#  gcc g++ make \
"

# ENV GITHUB_URL=https://raw.githubusercontent.com/tianxiawuzhe/alpine37-py365-django21-ai/master

RUN echo "Begin" && ls -lrt \
  && GITHUB_URL='https://github.com/tianxiawuzhe/php72fpm-alpine38-shop/raw/master' \
  && wget -O Dockerfile "${GITHUB_URL}/Dockerfile" \
  \
  && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  && echo "********** 安装永久依赖" \
  && apk add --no-cache $PACKAGES \
  && echo "********** 安装临时依赖" \
  && apk add --no-cache --virtual=.build-deps $BUILD_PACKAGES \
  \
##  && sed -i -e 's:mouse=a:mouse-=a:g' /usr/share/vim/vim81/defaults.vim \
##  \
  && echo "********** install 'pdo_mysql mysqli bcmath' ..." \
  && docker-php-ext-install pdo_mysql mysqli bcmath \
  \
  && echo "********** install 'gd' ..." \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  \
  && echo "********** install 'redis' ..." \
  && cd /tmp && redis=redis-5.3.2.tgz \
  && wget -O ${redis} "https://pecl.php.net/get/${redis}" \
  && (printf "no\nno\nno\n" | pecl install ${redis}) \
  && rm /tmp/${redis} \
  \
  && echo "********** enable install ..." \
  && docker-php-ext-enable pdo_mysql mysqli bcmath gd redis \
  && php -m | grep -E "(pdo_mysql|mysqli|bcmath|gd|redis)" \
  \
  && apk del .build-deps \
  && echo "End"

