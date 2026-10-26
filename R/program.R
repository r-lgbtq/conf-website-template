# Helpers for rendering the conference program from speaker and talk tables.
# Text columns (biography and abstract) are treated as Markdown.

program_slug <- function(text) {
  text <- tolower(text)
  text <- gsub("[^a-z0-9]+", "-", text)
  gsub("(^-+|-+$)", "", text)
}

program_write <- function(lines) {
  cat(paste(lines, collapse = "\n"), "\n\n", sep = "")
  invisible(lines)
}

program_cell <- function(row, column, default = NULL) {
  if (!column %in% names(row)) return(default)
  value <- row[[column]][1]
  if (is.na(value) || !nzchar(trimws(as.character(value)))) default else as.character(value)
}

program_require_columns <- function(data, columns, table_name) {
  missing <- setdiff(columns, names(data))
  if (length(missing)) stop(sprintf("%s is missing required column(s): %s", table_name, paste(missing, collapse = ", ")), call. = FALSE)
}

#' Make a program resource button
#'
#' @param label Text displayed on the button.
#' @param url Destination URL or site-relative file path.
#' @param icon Iconify icon name.
#' @return A single Quarto Markdown button string.
#' @export
program_resource <- function(label, url, icon = "mdi:link") {
  sprintf("[{{< iconify %s >}} %s](%s){.btn .icon-link}", icon, label, url)
}

program_links <- function(row) {
  definitions <- list(
    website = c("Website", "mynaui:globe"), github = c("GitHub", "simple-icons:github"),
    mastodon = c("Mastodon", "mdi:mastodon"), bluesky = c("Bluesky", "simple-icons:bluesky"),
    linkedin = c("LinkedIn", "mdi:linkedin"), recording = c("Talk recording", "mdi:youtube"),
    slides = c("Slides", "mdi:presentation"), repository = c("Repository", "mdi:github")
  )
  unlist(lapply(names(definitions), function(column) {
    url <- program_cell(row, column)
    if (is.null(url)) return(character())
    program_resource(definitions[[column]][1], url, definitions[[column]][2])
  }), use.names = FALSE)
}

#' Read program tables exported as CSV from a spreadsheet
#'
#' @param speakers_file Path to a CSV following the Speakers schema.
#' @param talks_file Path to a CSV following the Talks schema.
#' @return A named list containing `speakers` and `talks` data frames.
#' @export
read_program_csv <- function(speakers_file, talks_file) {
  list(
    speakers = utils::read.csv(speakers_file, check.names = FALSE, na.strings = ""),
    talks = utils::read.csv(talks_file, check.names = FALSE, na.strings = "")
  )
}

#' Read program tables directly from a Google Sheet
#'
#' The spreadsheet can stay private; `googlesheets4` requests authorization
#' while rendering.
#'
#' @param sheet_url Google Sheet URL or spreadsheet ID.
#' @param speakers_sheet Name of the speaker data tab.
#' @param talks_sheet Name of the talk data tab.
#' @return A named list containing `speakers` and `talks` data frames.
#' @export
read_program_sheets <- function(sheet_url, speakers_sheet = "Speakers", talks_sheet = "Talks") {
  if (!requireNamespace("googlesheets4", quietly = TRUE)) {
    stop("Install the `googlesheets4` package to read program data from Google Sheets.", call. = FALSE)
  }
  list(
    speakers = googlesheets4::read_sheet(sheet_url, sheet = speakers_sheet),
    talks = googlesheets4::read_sheet(sheet_url, sheet = talks_sheet)
  )
}

#' Render one speaker profile in the program
#'
#' @param name Speaker's displayed name.
#' @param bio Biography in Markdown, without the speaker name or pronouns.
#' @param pronouns Optional pronouns, without parentheses.
#' @param talk_title Optional linked talk title.
#' @param talk_id Optional anchor for the linked talk; required with `talk_title`.
#' @param id Speaker anchor. Defaults to a slug generated from `name`.
#' @param image Site-relative speaker image path.
#' @param image_alt Alternative text for the speaker image.
#' @param links Character vector of Markdown resource buttons.
#' @return Invisibly, the emitted Quarto Markdown lines.
#' @export
add_speaker <- function(name, bio, pronouns = NULL, talk_title = NULL, talk_id = NULL,
                        id = program_slug(name), image = "images/rainbowR-square.png",
                        image_alt = paste("Photograph of", name), links = character()) {
  if (xor(is.null(talk_title), is.null(talk_id))) stop("Supply both `talk_title` and `talk_id`, or neither.", call. = FALSE)
  display_name <- if (is.null(pronouns)) name else sprintf("%s (%s)", name, pronouns)
  lines <- c(sprintf("### %s {#%s}", name, id))
  if (!is.null(talk_title)) lines <- c(lines, sprintf("[%s](talks.qmd#%s)", talk_title, talk_id))
  program_write(c(lines, sprintf("![](%s){.person-img width=\"30%%\" fig-alt=\"%s\"}", image, image_alt), paste(display_name, bio), links))
}

#' Render all speakers from a `Speakers` response table
#'
#' Required: `name`, `bio`. Optional: `pronouns`, `slug`, `talk_title`,
#' `talk_slug`, `image`, `image_alt`, `website`, `github`, `mastodon`,
#' `bluesky`, and `linkedin`.
#'
#' @param speakers A data frame following the Speakers schema.
#' @return Invisibly, `NULL` after emitting Quarto Markdown for every row.
#' @export
add_speakers <- function(speakers) {
  program_require_columns(speakers, c("name", "bio"), "Speakers table")
  for (i in seq_len(nrow(speakers))) {
    row <- speakers[i, , drop = FALSE]
    name <- program_cell(row, "name")
    add_speaker(
      name = name, bio = program_cell(row, "bio", ""), pronouns = program_cell(row, "pronouns"),
      talk_title = program_cell(row, "talk_title"), talk_id = program_cell(row, "talk_slug"),
      id = program_cell(row, "slug", program_slug(name)),
      image = program_cell(row, "image", "images/rainbowR-square.png"),
      image_alt = program_cell(row, "image_alt", paste("Photograph of", name)), links = program_links(row)
    )
  }
}

#' Render one program talk entry
#'
#' @param title Talk title.
#' @param speaker Displayed speaker name.
#' @param abstract Optional talk abstract in Markdown.
#' @param id Talk anchor. Defaults to a slug generated from `title`.
#' @param speaker_id Anchor of the matching speaker.
#' @param kind One of `regular`, `keynote`, or `lightning`.
#' @param image Optional site-relative keynote image path.
#' @param image_alt Alternative text for `image`.
#' @param resources Character vector of Markdown resource buttons.
#' @param callout Callout color for regular and lightning talks.
#' @return Invisibly, the emitted Quarto Markdown lines.
#' @export
add_talk <- function(title, speaker, abstract = NULL, id = program_slug(title),
                     speaker_id = program_slug(speaker), kind = c("regular", "keynote", "lightning"),
                     image = NULL, image_alt = NULL, resources = character(), callout = NULL) {
  kind <- match.arg(kind)
  if (is.null(callout)) callout <- switch(kind, keynote = NULL, regular = "note", lightning = "tip")
  heading <- sprintf("### *%s*<br>[**%s**](speakers.qmd#%s) {#%s}", title, speaker, speaker_id, id)
  body <- c(heading)
  if (!is.null(image)) body <- c(body, sprintf("![](%s){fig-alt=\"%s\"}", image, if (is.null(image_alt)) paste("Image for", title) else image_alt))
  if (!is.null(abstract)) body <- c(body, "**Abstract:**", abstract)
  body <- c(body, resources)
  if (kind == "keynote") return(program_write(body))
  program_write(c(sprintf("::: {.callout-%s collapse=\"false\" icon=false appearance=\"simple\"}", callout), body, ":::"))
}

#' Render talks from a `Talks` response table
#'
#' Session headings are emitted when the `session` value changes. Keep rows in
#' their intended display order and group each session together.
#'
#' Required: `title`, `speaker`, `kind`. Optional: `abstract`, `slug`,
#' `speaker_slug`, `session`, `session_slug`, `image`, `image_alt`, `callout`,
#' `recording`, `slides`, and `repository`.
#'
#' @param talks A data frame following the Talks schema.
#' @param kind Optional talk kind used to filter `talks` before rendering.
#' @return Invisibly, `NULL` after emitting Quarto Markdown for every row.
#' @export
add_talks <- function(talks, kind = NULL) {
  program_require_columns(talks, c("title", "speaker", "kind"), "Talks table")
  if (!is.null(kind)) talks <- talks[talks$kind == kind, , drop = FALSE]
  previous_session <- NULL
  for (i in seq_len(nrow(talks))) {
    row <- talks[i, , drop = FALSE]
    talk_kind <- program_cell(row, "kind")
    session <- program_cell(row, "session")
    if (talk_kind != "keynote" && !is.null(session) && !identical(session, previous_session)) {
      add_session(session, program_cell(row, "session_slug", program_slug(session)))
      previous_session <- session
    }
    title <- program_cell(row, "title")
    speaker <- program_cell(row, "speaker")
    add_talk(
      title = title, speaker = speaker, abstract = program_cell(row, "abstract"),
      id = program_cell(row, "slug", program_slug(title)), speaker_id = program_cell(row, "speaker_slug", program_slug(speaker)),
      kind = talk_kind, image = program_cell(row, "image"), image_alt = program_cell(row, "image_alt"),
      resources = program_links(row), callout = program_cell(row, "callout")
    )
  }
}

#' Render a program session heading
#'
#' @param title Session title.
#' @param id Session anchor. Defaults to a slug generated from `title`.
#' @return Invisibly, the emitted Quarto Markdown lines.
#' @export
add_session <- function(title, id = program_slug(title)) {
  program_write(sprintf("### %s {#%s}", title, id))
}
