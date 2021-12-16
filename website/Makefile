DOMAIN			= pipeline.shared-search.eu
PUBLISH_WEBSITE	= $(SKRODON_PUBLISH)/$(DOMAIN)/public_html/
TEST_WEBSITE	= $(PIPELINE_WEBSITE)/

webpages::
	bin/produce_webpages

publish:: webpages
	rsync --archive --update --rsh=/usr/bin/ssh --delete \
	  $(TEST_WEBSITE) \
	  $(PUBLISH_WEBSITE)
