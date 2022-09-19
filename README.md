# docker-php-symfony
## Docker PHP 8.1 for symfony development

### Contains 
 * php FPM 8.1, xdebug 3.0
 * redis with igbinary
 * pdo, mysql, pgsql
 * bcmath curl gd intl json mbstring readline soap xml xmlrpc xsl zip
 * composer
 * xdebug on port 9003
 * mail routed to mailhog:1025 (you need to create this service)
 
### Ports exposed
 * 9000 - PHP FPM

### Ports opened to host
 * 9003 - xDebug

 