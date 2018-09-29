#' Get sounding data for a station
#'
#' @md
#' @param station_number the station number
#' @param date an ISO character string (e.g. `YYYY-mm-dd`) or a valid `Date` object
#' @param include_frost if `TRUE`, include frost point calculations. Default: `FALSE`
#' @param region one of "`naconf`", "`samer`", "`pac`", "`nz`", "`ant`", "`np`",
#'        "`europe`", "`africa`", "`seasia`", "`mideast`" (which matches the
#'        values of the drop-down menu on the site). Use [get_region_codes()]
#'        to get a mapping of region names to valid region codes.
#' @param from_hr,to_hr one of `00` (or `0`), `12` or `all`; if `all` then both
#'        values will be set to `all`
#' @return data frame of soundings data with a "`meta`" attribute that contains
#'         metadata about the station and result. Also, the date and from/to hours
#'         are added columns to make it easier to save and reuse the data.
#' @export
get_sounding_data <- function(station_number,
                              date,
                              include_frost = FALSE,
                              region = c(
                                "naconf", "samer", "pac", "nz", "ant",
                                "np", "europe", "africa", "seasia", "mideast"
                              ),
                              from_hr = c("00", "12", "all"),
                              to_hr = c("00", "12", "all")) {

  # validate region
  region <- match.arg(
    arg = region,
    choices = c(
      "naconf", "samer", "pac", "nz", "ant",
      "np", "europe", "africa", "seasia", "mideast"
    )
  )

  # this actually validates the date for us if it's a character string
  date <- as.Date(date)

  # get year and month
  year <- as.integer(format(date, "%Y"))
  stopifnot(year %in% 1973:as.integer(format(Sys.Date(), "%Y")))

  year <- as.character(year)
  month <- format(date, "%m")

  o_from_hr <- from_hr <- as.character(tolower(from_hr))
  o_to_hr <- to_hr <- as.character(tolower(to_hr))

  if ((from_hr == "all") || (to_hr == "all")) {

    from_hr <- to_hr <- "all"

  } else {

    from_hr <- hr_trans[sprintf("%s/%02dZ", format(date, "%d"), as.integer(from_hr))]
    match.arg(from_hr, hr_vals)

    to_hr <- hr_trans[sprintf("%s/%02dZ", format(date, "%d"), as.integer(to_hr))]
    match.arg(to_hr, hr_vals)

  }

  # clean up the station number if it was entered as a double
  station_number <- as.character(as.integer(station_number))

  query = list(
    region = region,
    TYPE = "TEXT:LIST",
    YEAR = year,
    MONTH = sprintf("%02d", as.integer(month)),
    FROM = from_hr,
    TO = to_hr,
    STNM = station_number
  ) -> params

  if (include_frost) query$ICE <- "1"

  # execute the API call
  httr::GET(
    url = "http://weather.uwyo.edu/cgi-bin/sounding",
    query = params
  ) -> res

  # check for super bad errors (that we can't handle nicely)
  httr::stop_for_status(res)

  # get the page content
  doc <- httr::content(res, as="text")

  # if the site reports no data, issue a warning and return an empty data frame
  if (grepl("Can't get", doc)) {
    doc <- xml2::read_html(doc)
    msg <- rvest::html_nodes(doc, "body")
    msg <- rvest::html_text(msg, trim=TRUE)
    msg <- gsub("\n\n+.*$", "", msg)
    warning(msg)
    return(data.frame(stringsAsFactors=FALSE))
  }

  # turn it into something we can parse
  doc <- xml2::read_html(doc)

  # get the metadata
  meta <- rvest::html_node(doc, "h2")
  meta <- rvest::html_text(meta, trim=TRUE)

  # get the table
  doc <- rvest::html_nodes(doc, "pre")[[1]]
  doc <- rvest::html_text(doc, trim=TRUE)
  doc <- strsplit(doc, "\n")[[1]]

  # extract the column names and make them really nice and informative
  col_names <- doc[2:3]
  gsub(
    "_+", "_",
    gsub(
      "[[:punct:]]", "_",
      gsub(
        "%", "pct", tolower(
          sprintf(
            "%s_%s",
            unlist((strsplit(trimws(col_names[1]), "[[:space:]]+"))),
            unlist((strsplit(trimws(col_names[2]), "[[:space:]]+")))
          )
        )
      )
    )
  ) -> col_names

  # parse the values correctly (this is better than read.table)
  con <- textConnection(doc[-c(1:4)])
  read.fwf(
    file = con,
    widths = rep(7, 11),
    header = FALSE,
    colClasses = rep("character", 11), # we'll convert them ourselves, tyvm
    stringsAsFactors=FALSE
  ) -> xdf

  # get rid of white space in each column
  xdf[] <- lapply(xdf, trimws)

  # turn them all numeric
  xdf[] <- suppressWarnings(lapply(xdf, as.numeric))

  # set our column names
  colnames(xdf) <- col_names

  # add the date and from/to hr as columns
  xdf$date <- date
  xdf$from_hr <- o_from_hr
  xdf$to_hr <- o_to_hr

  # this affords pretty-printing if you use the tidyverse
  class(xdf) <- c("tbl_df", "tbl", "data.frame")

  # add the metadata as an unobtrusive attribute
  attr(xdf, "meta") <- meta

  xdf

}