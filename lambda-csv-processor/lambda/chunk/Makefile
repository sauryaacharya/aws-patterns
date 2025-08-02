DIST_DIR := dist
ZIP_FILE := chunk-lambda.zip
SRC_FILES := index.js package.json package-lock.json

.PHONY: clean build zip all

clean:
	rm -rf $(DIST_DIR) $(ZIP_FILE)

build-package:
	mkdir -p $(DIST_DIR)
	cp $(SRC_FILES) $(DIST_DIR)/
	cd $(DIST_DIR) && npm ci --omit=dev

zip-package: build-package
	zip -r $(ZIP_FILE) $(DIST_DIR)

build: clean zip-package
