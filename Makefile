APP = build/Escoba.app
INSTALLED = /Applications/Escoba.app

.PHONY: build run install clean

build:
	./scripts/build-app.sh

run: build
	open "$(APP)"

# El login item (SMAppService) y las notificaciones funcionan mejor con la
# app en una ubicación estable como /Applications.
install: build
	rm -rf "$(INSTALLED)"
	cp -R "$(APP)" "$(INSTALLED)"
	open "$(INSTALLED)"

clean:
	rm -rf .build build
