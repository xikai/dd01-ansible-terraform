# Ansible php install role

Support Ubuntu 16 to install php 7.0, 7.1, 7.2

## Role Variables

    php_version: '7.2'

    php_ex_packages:
        - php-redis

## Other
The role will install some packages default

    php{{ php_version }}-curl
    php{{ php_version }}-mysql
    php{{ php_version }}-mongodb
    php{{ php_version }}-mbstring
    php{{ php_version }}-dev
    php{{ php_version }}-fpm
    php{{ php_version }}-dev
    php{{ php_version }}-curl
    php{{ php_version }}-mbstring
    php{{ php_version }}-pdo-mysql
    php{{ php_version }}-pdo
    php{{ php_version }}-opcache
    php{{ php_version }}-apcu
    php{{ php_version }}-redis



