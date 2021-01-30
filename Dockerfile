FROM php:7.2-fpm-alpine

COPY etc  /usr/local/etc
#COPY github_hosts /tmp/
COPY Shanghai /etc/localtime

##ENV ALPINE_VERSION=3.8
ENV TIMEZONE=Asia/Shanghai
ENV PHP_MEMORY_LIMIT=512M
ENV MAX_UPLOAD=50M
ENV PHP_MAX_FILE_UPLOAD=200
ENV PHP_MAX_POST=100M

#### packages from https://pkgs.alpinelinux.org/packages
# These are always installed. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * bash: For entrypoint, and debugging
#   * libpng  freetype libjpeg-turbo: For gd 
#   * m4 autoconf: For redis
#  bash vim \
ENV PACKAGES="\
  libpng  freetype libjpeg-turbo \
  m4 autoconf \
"

# These packages are not installed immediately, but are added at runtime or ONBUILD to shrink the image as much as possible. Notes:
#   * build-base: used so we include the basic development packages (gcc)
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
ENV BUILD_PACKAGES="\
  build-base \
  libpng-dev freetype-dev libjpeg-turbo-dev \
"

# ENV GITHUB_URL=https://raw.githubusercontent.com/tianxiawuzhe/alpine37-py365-django21-ai/master

RUN echo "Begin" && echo '199.232.68.133 raw.githubusercontent.com' >> /etc/hosts \
  && echo "${TIMEZONE}" > /etc/timezone \
  && cd / \
  && GITHUB_URL='https://github.com/tianxiawuzhe/php72fpm-alpine38-shop/raw/master' \
  && wget -O Dockerfile "${GITHUB_URL}/Dockerfile" \
  \
  && cd /usr/local/bin/ \
  && wget -O composer "https://getcomposer.org/download/2.0.8/composer.phar" \
  && chmod +x /usr/local/bin/composer \
  && /usr/local/bin/composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
  \
  && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
  && echo "********** 安装永久依赖" \
  && apk add --no-cache $PACKAGES \
  && echo "********** 安装临时依赖" \
  && apk add --no-cache --virtual=.build-deps $BUILD_PACKAGES \
  \
#  && sed -i -e 's:mouse=a:mouse-=a:g' /usr/share/vim/vim8?/defaults.vim \
#  \
  && echo "********** install 'pdo_mysql' ..." \
  && docker-php-ext-install pdo_mysql \
  \
  && echo "********** install 'mysqli' ..." \
  && docker-php-ext-install mysqli \
  \
  && echo "********** install 'bcmath' ..." \
  && docker-php-ext-install bcmath \
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

