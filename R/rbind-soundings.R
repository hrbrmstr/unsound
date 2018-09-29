#' Turn a list of soundings data frames into a single data frame
#'
#' A likely idiom used with this pacakge is to generate a sequence
#' of dates and then retrieve soundings data for those dates and
#' then turn them into one, big-ish data frame. Generating the
#' list of data frames is up to the caller but said list can then
#' be passed to this function to safely [rbind()] them into a data frame.
#' Empty results will be ignored.
#'
#' @md
#' @param x a `list` of soundings `data.frame`s
#' @return a "`rbind`ed" single data frame
#' @export
rbind_soundings <- function(x) {

  Reduce(
    rbind.data.frame,
    Filter(length_not_zero, x)
  ) -> xdf

  class(xdf) <- c("tbl_df", "tbl", "data.frame")

  xdf

}