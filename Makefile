.DEFAULT_GOAL := help

help:
	@echo ""
	@echo "Available tasks:"
	@echo "    watch   Rebuild site when sources change."
	@echo "    server  Start internal webserver"
	@echo ""

server:
	hugo server

build:
	hugo

deploy:
	hugo
	#65.109.28.46
	rsync --verbose  --rsh=ssh --recursive public/ ansible@65.109.28.46:/srv/www/www.appelsiini.net/public
	scp public/.htaccess ansible@65.109.28.46:/srv/www/www.appelsiini.net/public
	scp public/.well-known/openpgpkey/hu/.htaccess ansible@65.109.28.46:/srv/www/www.appelsiini.net/public/.well-known/openpgpkey/hu/

	#rsync --verbose  --rsh=ssh --recursive public/ tuupola@172.104.142.48:/srv/www/appelsiini.net/public
	#scp public/.htaccess tuupola@172.104.142.48:/srv/www/appelsiini.net/public
	#scp public/.well-known/openpgpkey/hu/.htaccess tuupola@172.104.142.48:/srv/www/appelsiini.net/public/.well-known/openpgpkey/hu/

.PHONY: help server build