# CommonCrawl results processing

CommonCrawl produces about 320TB of WARC files per month, in 64000+ separate
files.  These are downloaded one after the other.

## Maintenance

### Start processing a new dataset

In the current state of this software, we start the processing by
hand.  The next collects the various path names of resource files.

```bash
run CommonCrawl release-kickoff 2021-17
```

The week number (17) is the week their crawling was started.  Ideally, we get
the files on the moment they are produced, not all at the same time at the
end of the collection.

### Feeding the pipeline

Every few minutes, cron will use `incoming-queue` on each of the CRAWL,
WAT and WET set, to see whether the "incoming" directories are filled
sufficiently.  They have to be processed within an hour, otherwise
are lost.

### Parallel processing

The `warc-pipeline` starts the batch-processing for sets of collected
WARCs, with a configurable number of processes in parallel.  Each set
is handled by a separate `process-batch` command.

## Directories

- `CommonCrawl/CRAWL-paths-todo` file per WARC to be downloaded
- `CommonCrawl/WAT-paths-todo`
- `CommonCrawl/WET-paths-todo`
- `CommonCrawl/CRAWL-warcs-incoming` cached loaded WARCs
- `CommonCrawl/WAT-warcs-incoming`
- `CommonCrawl/WET-warcs-incoming`
- `CommonCrawl/locks` locks to avoid processes to disturb each other
- `CommonCrawl/processing` active pipe-lines

## Some timing

On the current hardware, the pipeline itself takes about 1m20 per set.
Logic is expected to consume at least 40 seconds per file.  So: at least
2 minutes per file.

CommonCrawl produces 64000 files per month, which means that we need
to process one file per 40 seconds on average: run least three processes
in parallel full time.

We do not need to count downloading in, which is done in the background.
Per file of 1GB, it only takes a few seconds (typically 5 to 10) to 
fetch them from AWS s3.  AWS offers smaller files much slower than the
larger files: the download start-time is seconds.

