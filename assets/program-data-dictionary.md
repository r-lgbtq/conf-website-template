# Program data dictionary

The Quarto program pages read two tables. Keep their headers exactly as shown
in the supplied CSV templates. A blank optional cell is ignored. Text in `bio`
and `abstract` is rendered as Markdown, so it may contain links and emphasis.

## Speakers table

| Column | Required | Format and purpose |
|---|---:|---|
| `kind` | Yes | `keynote` for keynote speakers or `talk` for all other speakers. |
| `name` | Yes | Display name. |
| `pronouns` | No | Pronouns without parentheses, for example `she/her` or `they/them`. |
| `bio` | Yes | Biography, ideally written as a sentence beginning with a role or verb, since the rendered page prefixes it with the speaker's name and pronouns. |
| `talk_title` | No | Exact title of the linked talk. |
| `talk_slug` | No | Anchor from the matching Talks row's `slug` column. |
| `slug` | No | Unique, lowercase, hyphenated speaker anchor, for example `alex-smith`. Defaults to a slug made from `name`. |
| `image` | No | Site-relative image path, for example `images/people/alex-smith.jpg`. |
| `image_alt` | No | Useful image description. Defaults to `Photograph of {name}`. |
| `website` | No | Full `https://` website URL. |
| `github` | No | Full GitHub profile URL. |
| `mastodon` | No | Full Mastodon profile URL. |
| `bluesky` | No | Full Bluesky profile URL. |
| `linkedin` | No | Full LinkedIn profile URL. |

## Talks table

Keep talks in their intended display order. For regular talks, place all talks
in the same session together so each session heading is emitted once.

| Column | Required | Format and purpose |
|---|---:|---|
| `kind` | Yes | One of `keynote`, `regular`, or `lightning`. |
| `session` | No | Session heading for a regular or lightning talk, for example `Session I`. Leave blank when no heading is wanted. |
| `session_slug` | No | Unique, lowercase, hyphenated anchor for the session. Defaults to a slug made from `session`. |
| `title` | Yes | Talk title. |
| `speaker` | Yes | Exact speaker name, matching the Speakers table. |
| `speaker_slug` | No | Anchor from the matching Speakers row's `slug` column. Defaults to a slug made from `speaker`. |
| `slug` | No | Unique, lowercase, hyphenated talk anchor. Defaults to a slug made from `title`. |
| `abstract` | No | Talk abstract in Markdown. |
| `image` | No | Site-relative image path; typically used for a keynote graphic. |
| `image_alt` | No | Useful alternative text for `image`. |
| `callout` | No | For regular/lightning talks: `note`, `tip`, `caution`, `warning`, or `important`. Defaults to `note` for regular and `tip` for lightning talks. |
| `recording` | No | Full recording URL. |
| `slides` | No | URL or site-relative path to slides. |
| `repository` | No | Full repository URL. |

## Google Forms and Sheets

Use the form response sheet as intake, then copy approved and edited responses
into `Speakers` and `Talks` tabs with the columns above. Either download those
tabs as the two CSV files in this folder, or call `read_program_sheets()` with
the Google Sheet URL when rendering. The latter requires the `googlesheets4`
package and Google authorization for a private sheet.
