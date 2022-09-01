
webpages::
	bin/produce_webpages

publish:: webpages
	@ if [ -z "$(MARKOV_DEVEL)" ]; \
	  then echo "Upload currently only by MarkOv" >&2; exit 1; \
	  fi
	psync pipeline
