BINARY = RePrompt
APP = $(BINARY).app
SOURCES = $(wildcard Sources/RePrompt/*.swift)
FRAMEWORKS = -framework AppKit -framework AVFoundation -framework AVKit -framework CoreGraphics -framework IOKit

.PHONY: build app run clean install

build: $(BINARY)

$(BINARY): $(SOURCES)
	swiftc -o $(BINARY) $(FRAMEWORKS) $(SOURCES)

app: $(BINARY)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	mkdir -p $(APP)/Contents/Resources
	cp $(BINARY) $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/

run: build
	./$(BINARY)

install: app
	rm -rf /Applications/$(APP)
	cp -r $(APP) /Applications/
	@echo "$(APP) を /Applications にインストールしました"

clean:
	rm -f $(BINARY)
	rm -rf $(APP)
