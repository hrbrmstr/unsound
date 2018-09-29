.get_region_codes <- function() {

  doc <- xml2::read_html("http://weather.uwyo.edu/upperair/naconf.html")
  regions <- rvest::html_nodes(doc, xpath=".//select[@name='region']/option")

  data.frame(
    region_name = rvest::html_text(regions, trim=TRUE),
    region_code = rvest::html_attr(regions, "value"),
    stringsAsFactors = FALSE
  ) -> xdf

  class(xdf) <- c("tbl_df", "tbl", "data.frame")

  xdf

}

#' Retrive region names and codes
#'
#' @md
#' @return a data frame of region codes and names. The codes can be used
#'         as parameters in other functions that take region codes.
#' @export
get_region_codes <- memoise::memoise(.get_region_codes)
