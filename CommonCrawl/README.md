# CommonCrawl results processing

CommonCrawl produces about 320TB of WARC files per month, in 64000+ separate
files.  These are downloaded one after the other.

## Start processing a new dataset

```bash
run CommonCrawl release-kick-off 2021-17
```

The week number (17) is the week their crawling was started.  Ideally, we get
the files on the moment they are produced, not all at the same time at the
end of the process.

## Feeding the pipeline

Every few minutes, cron will call `incoming-warcs` on each of the CRAWL, WAT
and WET set, so see whether the "incoming" directories are filled sufficiently.
They have to be processed within an hour, otherwise are lost.

  process-batch  warc-pipeline
