# Creating the website

## Preparation

 - Where is your work environment? --> `WORKDIR`
 - Where are your website documents?  --> `HVOST`
 - Put `export PIPELINE_WEBSITE="$VHOST/crawl-pipeline"` in your login profile.
 - `cd $WORKDIR && git clone git@github.com:markov2/crawl-pipeline`
 - Now create an (apache httpd) virtual host with document root `$PIPELINE_WEBSITE`.  This is your test instance of the website.

## To update

 - `cd $WORKDIR/crawl-pipeline/website`
 - `git pull`
 - Create changes in `raw/` (we are not going to use branches)
 - `make`
 - Check changes in the browser
 - `git commit -a`
 - `git push`
 - `make publish`

## Processing

"make" calls `bin/produce_website` which is a smart script, whic
  - copies all files which are not ending in `.raw` or `.incl` to the same location in the produced website.  Be warned: also files which end on `.html` will get copied "as is".
  - every file which ends on `.raw` will lead to an html file with the same base name.
  - `.incl` files are included in `.raw` files, and will not produce a separate html file by themselves.
  - there are various sanity checks performed.

# Syntax of RAW files

  - Each file starts with a `<h1>`, which is automatically also used for the `<title>`
  - External links (`a href`) will automatically get a `target="blank"`, hence open in a separate window.
  - Links (`a href`) to the page itself are replaces by a `<span class="myself"` which shows them bold and unclickable.
  - Each `<h2>` gets a `<hr>` in front of it.
  - The file starts filling the left column.  A `--right` will indicate the start of a block to be displayed in the right column.  And this block ends with a `--left` or EndOfFile.  Etcetera.
  - The nicest presentation of the page is more important than a logical order of the blocks.
  - You may decide to split between columns when a chapter gets too large.  No problem, but you need to add an `<hr>` yourself in your continuation block.
  - You can use special code blocks, described below.

Libraries:
  - use Bootstrap 5 for layout and widgets
  - use jQuery for dynamics
  - use fontawesome for icons: try to avoid using tiny images

# Syntax of Code blocks within RAW files

Code blocks show a fragment of code or protocol.  There are four kinds:
   - `PLAIN` (plain text)
   - `JSON`
   - `XML`
   - `PERL`

Rules:
  - Inside these blocks, dangerous entities get escaped for you.  For instance, `<`, `>` and `"`.
  - The contents gets syntax highlighted (except for PLAIN)

When you use one block, you get a simple blue box with preformatted text.  When you have more than one in a row, you will get a tabbed window with (f.i.) XML and JSON as tab names.  The content MUST be exactly the same logically --only show alternative syntaxes.

You may add a `<HEADER>` container right before the (list of) code blocks, to get a text above the blue box (or tabbed display).

Each block starter may carry flags.  At the moment, this are the choices:
   - `copy`, make it easy to copy the plain content of a box.
   - `nrs`, add line-numbers to each line in the box.

Example:
```
  <HEADER>This is an example</HEADER>
  <JSON nrs copy>
    { "answer": 42 }
  </JSON>
  <XML>
     <xml><answer>42</answer></xml>
  </XML>
```
