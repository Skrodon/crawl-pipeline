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

## Parallel processing

The ``warc-pipeline`` starts the batch-processing for sets of collected
WARCs, with a configurable number of processes in parallel.  Earch set
is handled by a separate ``process-batch`` command.

## Some timing

On the current hardware, the pipeline itself takes about 1m20 per set.
Logic is expected to consume at least 40 seconds per file.  So: at least
2 minutes per file (we do not need to count downloading in, which is
done in the background)

CommonCrawl produces 64000 files per month, which means that we need
to process one file per 40 seconds on average: run least three processes
in parallel full time.
