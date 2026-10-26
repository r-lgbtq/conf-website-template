# rainbowR conference website template

This is a Quarto template for a future rainbowR conference website. 

## Program entries

The rendering helpers are an R package named `rainbowrprogram`: code lives in
`R/`, public functions are documented in `man/`, and `NAMESPACE` is generated
from roxygen comments. The Quarto pages source `R/program.R` directly when
rendered from this repository.

`R/program.R` renders program content from two tables, so speaker
biographies and abstracts are never copied into the Quarto pages. The shipped
CSV templates are [program-speakers.csv](assets/program-speakers.csv) and
[program-talks.csv](assets/program-talks.csv); the active pages read these
files with `read_program_csv()` then use `add_speakers()` and `add_talks()`.

Use a Google Form to collect the responses, curate them into `Speakers` and
`Talks` tabs in a Google Sheet, then export each tab as CSV over the two files
above. Alternatively, replace `read_program_csv()` in both pages with
`read_program_sheets(SHEET_URL)`, which reads those tabs directly with the
`googlesheets4` package.

The speaker table requires `name` and `bio`; `pronouns` is its own optional
column. The talk table requires `title`, `speaker`, and `kind` (`keynote`,
`regular`, or `lightning`). The templates include optional columns for image
metadata, session headings, social links, recordings, slides, and repositories.
The full field reference is in [assets/program-data-dictionary.md](assets/program-data-dictionary.md).

