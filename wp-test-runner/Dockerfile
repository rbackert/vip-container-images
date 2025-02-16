FROM cimg/base:stable-20.04@sha256:35e5e29930ab565475a4f2aa9b4124998ed67dbc7b0e2dd5f420a4189d08d0d2

USER root
RUN \
	export DEBIAN_FRONTEND=noninteractive; \
	echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
	apt-get -qq update && apt-get -qq install eatmydata && \
	add-apt-repository -y ppa:ondrej/php && \
	eatmydata apt-get -qq upgrade && \
	eatmydata apt-get -qq install php7.4 php7.4-apcu php7.4-curl php7.4-gd php7.4-gmp php7.4-igbinary php7.4-imagick php7.4-imap php7.4-intl php7.4-mbstring php7.4-mysql php7.4-sqlite3 php7.4-xdebug php7.4-xml php7.4-xsl php7.4-zip php7.4-memcache php7.4-memcached && \
	eatmydata apt-get -qq install php8.0 php8.0-apcu php8.0-curl php8.0-gd php8.0-gmp php8.0-igbinary php8.0-imagick php8.0-imap php8.0-intl php8.0-mbstring php8.0-mysql php8.0-sqlite3 php8.0-xdebug php8.0-xml php8.0-xsl php8.0-zip php8.0-memcache php8.0-memcached && \
	eatmydata apt-get -qq install php8.1 php8.1-apcu php8.1-curl php8.1-gd php8.1-gmp php8.1-igbinary php8.1-imagick php8.1-imap php8.1-intl php8.1-mbstring php8.1-mysql php8.1-sqlite3 php8.1-xdebug php8.1-xml            php8.1-zip php8.1-memcache php8.1-memcached && \
	eatmydata apt-get -qq install php8.2             php8.2-curl php8.2-gd php8.2-gmp                                php8.2-imap php8.2-intl php8.2-mbstring php8.2-mysql php8.2-sqlite3               php8.2-xml            php8.2-zip                                  && \
	eatmydata apt-get -qq install subversion unzip default-mysql-client && \
	apt-get clean && rm -rf /var/lib/apt/lists/* && \
	echo "xdebug.mode=coverage" | tee -a /etc/php/*/mods-available/xdebug.ini && \
	update-alternatives --set php /usr/bin/php8.0

RUN install -d -o circleci -g circleci -m 0777 /wordpress
RUN wget -q https://getcomposer.org/installer -O - | php -- --install-dir=/usr/bin/ --filename=composer

RUN \
	wget -q -O /usr/local/bin/phpunit7 https://phar.phpunit.de/phpunit-7.phar & \
	wget -q -O /usr/local/bin/phpunit8 https://phar.phpunit.de/phpunit-8.phar & \
	wget -q -O /usr/local/bin/phpunit9 https://phar.phpunit.de/phpunit-9.phar & \
	wget -q -O /usr/local/bin/phpcov   https://phar.phpunit.de/phpcov.phar & \
	wait; \
	chmod +x /usr/local/bin/phpunit7 /usr/local/bin/phpunit8 /usr/local/bin/phpunit9 /usr/local/bin/phpcov

USER circleci

ENV LD_PRELOAD /usr/lib/x86_64-linux-gnu/libeatmydata.so

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
ENV NVM_DIR /home/circleci/.nvm

RUN \
    . "${NVM_DIR}/nvm.sh" && \
    nvm install --lts && \
    nvm use --lts

USER root
COPY install-wp.sh /usr/local/bin/install-wp

USER circleci
RUN \
	WP_VERSIONS=$(wget https://api.wordpress.org/core/version-check/1.7/ -q -O - | jq -r '[.offers[].version] | unique | map(select( . >= "5.5")) | .[]'); \
	for version in ${WP_VERSIONS} latest; do \
		install-wp "${version}" & \
	done && \
	wait

RUN install-wp nightly

USER root
COPY configure-environment.sh /usr/local/bin/configure-environment
COPY create-database.sh /usr/local/bin/create-database
COPY runner.sh /usr/local/bin/runner
ENTRYPOINT ["/usr/local/bin/runner"]

USER circleci
