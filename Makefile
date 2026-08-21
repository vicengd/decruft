APP = build/Decruft.app
INSTALLED = /Applications/Decruft.app

.PHONY: build run install clean dmg

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

# DMG con alias a /Applications para instalar arrastrando.
dmg: build
	rm -rf build/dmg-staging build/Decruft.dmg
	mkdir -p build/dmg-staging
	cp -R "$(APP)" build/dmg-staging/
	ln -s /Applications build/dmg-staging/Applications
	hdiutil create -volname "Decruft" -srcfolder build/dmg-staging -ov -format UDZO build/Decruft.dmg
	rm -rf build/dmg-staging
