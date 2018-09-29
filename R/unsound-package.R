#' Retrieve Current and Historical Upper Air Soundings Data from the University of Wyoming
#'
#' The University of Wyoming maintains a server (<http://weather.uwyo.edu/upperair/sounding.html>)
#' that provides an interface to query current and historical upper air soundings
#' data. Tools are provided to query this service and retrieve the data.
#'
#' - <https://stackoverflow.com/questions/52535696/save-content-in-web-as-data-frame/52539658#52539658>
#' - <https://stackoverflow.com/questions/52543892/web-scraping-using-httr-give-xml-nodeset-error/52545775?noredirect=1#comment92066543_52545775>
#' - URL: <https://gitlab.com/hrbrmstr/unsound>
#' - BugReports: <https://gitlab.com/hrbrmstr/unsound/issues>
#'
#' @md
#' @name unsound
#' @docType package
#' @author Bob Rudis (bob@@rud.is)
#' @import httr
#' @import xml2
#' @import rvest
#' @importFrom memoise memoise
#' @importFrom jsonlite fromJSON
NULL
