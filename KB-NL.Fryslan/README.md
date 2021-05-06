# Dutch National Library (KB), collecting Fryslân

As experiment, the [KB](https://kb.nl) implemented a crawler which
collects web-pages about the Dutch province Fryslân (Friesland).
Fryslân has its own distinctive language and top-level name-space (TLD)
`.frl`

This component produces an extra of the Pipeline, which contains WARC
records which match one of the following conditions
  - hostname in .frl
  - url matches /\b(fryslan|friesland)\b/
  - response is in the frysian language
  - the page's text extract contains /\b(fryslan|friesland)\b/

Although it is easy to produce WARC files for this, we chose to produce
a compact 7zip, with an index.  This may change later.
