#' Retrieve pre-generated map for sounding data
#'
#' @md
#' @param station_number the station number
#' @param date an ISO character string (e.g. `YYYY-mm-dd`) or a valid `Date` object
#' @param map_type one of "`skewt`" for Skew-T, "`stuve`" for Stuve,
#'       "`stuve10`" for Stuve to 10 mb, "`stuve700`" for Stuve to 700 mb,
#'       "`hodo`" for Hodograph. Defaults to "`skewt`"
#' @param map_format one of "`gif`" or "`pdf`". Default is "`gif`"
#' @param include_frost if `TRUE`, include frost point calculations. Default: `FALSE`
#' @param region one of "`naconf`", "`samer`", "`pac`", "`nz`", "`ant`", "`np`",
#'        "`europe`", "`africa`", "`seasia`", "`mideast`" (which matches the
#'        values of the drop-down menu on the site). Use [get_region_codes()]
#'        to get a mapping of region names to valid region codes.
#' @param from_hr,to_hr one of `00` (or `0`), `12` or `all`; if `all` then both
#'        values will be set to `all`
#' @return a `magick` object containing the `gif` or `pdf` requested.
#' @note the PDF may be blank or the result may be `NULL` (if a GIF was requested)
#'       if there is no data for a given day.
#' @export
get_sounding_map <- function(station_number,
                             date,
                             map_type = c("skewt", "stuve", "stuve10", "stuve700", "hodo"),
                             map_format = c("pdf", "gif"),
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
    TYPE = sprintf("%s:%s", toupper(map_format), toupper(map_type)),
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

  if (grepl("pdf", res$headers["content-type"])) {

    magick::image_read(httr::content(res), as="raw")

  } else {

    # get the page content
    doc <- httr::content(res, as="text")

    # if the site reports no data, issue a warning and return an empty data frame
    if (grepl("Sorry", doc)) {
      warning("Remote server was unable to generate a map for those parameters.")
      return(invisible(NULL))
    }

    # turn it into something we can parse
    doc <- xml2::read_html(doc)

    img <- rvest::html_node(doc, "img")
    img_url <- sprintf("http://weather.uwyo.edu%s", rvest::html_attr(img, "src"))

    magick::image_read(img_url)

  }

}