DOMAIN			= pipeline.shared-search.eu
PUBLIC_WEBSITE	= markovoc@$(DOMAIN):domains/$(DOMAIN)/public_html/
TEST_WEBSITE	= $(PIPELINE_WEBSITE)/

webpages::
	bin/produce_webpages

publish:: webpages
	rsync --archive --update --rsh=/usr/bin/ssh --delete \
	  $(TEST_WEBSITE) \
	  $(PUBLIC_WEBSITE)
