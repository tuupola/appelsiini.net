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
	rsync --verbose  --rsh=ssh --recursive public/ tuupola@butter.appelsiini.net:/srv/www/appelsiini.net/public
	scp public/.htaccess tuupola@butter.appelsiini.net:/srv/www/appelsiini.net/public

.PHONY: help server build