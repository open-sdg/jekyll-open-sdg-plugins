.PHONY: clean build serve serve.detached
all: test

clean:
	# Stop the detached Jekyll web server.
	-pkill -f -9 jekyll
	# Delete the builds.
	rm -fr open-sdg-site-starter
	rm -fr open-sdg

build: clean
	git clone https://github.com/open-sdg/open-sdg-site-starter.git
	git clone https://github.com/open-sdg/open-sdg.git
	# Copy all the theme files into the site starter.
	cp -r open-sdg/_includes/* open-sdg-site-starter/_includes/
	cp -r open-sdg/_layouts/* open-sdg-site-starter/_layouts/
	cp -r open-sdg/_sass/* open-sdg-site-starter/_sass/
	cp -r open-sdg/assets/* open-sdg-site-starter/assets/
	# Copy the required files into the site starter.
	cp tests/_config.yml open-sdg-site-starter/
	cp tests/Gemfile open-sdg-site-starter/
	# Create a symlink to our plugin files.
	ln -s ../lib/jekyll-open-sdg-plugins open-sdg-site-starter/_plugins
	# Build the Jekyll site.
	cd open-sdg-site-starter && bundle install
	cd open-sdg-site-starter && bundle exec jekyll build

serve: build
	cd open-sdg-site-starter && bundle exec jekyll serve --skip-initial-build
