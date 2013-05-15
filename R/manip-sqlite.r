#' Data manipulation for SQL data sources.
#'
#' Arrange, filter and select are lazy: they modify the object representing
#' the table, and do not recompute unless needed.  Summarise and mutate
#' are eager: they will always return a source_data_frame.
#'
#' @examples
#' baseball_s <- sqlite_source("inst/db/baseball.sqlite3", "baseball")
#'
#' # filter, select and arrange lazily modify the specification of the table
#' # they don't execute queries unless you print them
#' filter(baseball_s, year > 2005, g > 130)
#' select(baseball_s, id:team)
#' arrange(baseball_s, id, desc(year))
#'
#' # summarise and mutate always return data frame sources
#' summarise(baseball_s, g = mean(g), n = count())
#' mutate(baseball_s, rbi = 1.0 * r / ab)
#'
#' @name manip_sqlite
NULL

#' @rdname manip_sqlite
#' @export
#' @method filter source_sqlite
filter.source_sqlite <- function(.data, ...) {
  input <- partial_eval(.data, dots(...), parent.frame())
  .data$filter <- c(.data$filter, input)
  .data
}

#' @rdname manip_sqlite
#' @export
#' @method arrange source_sqlite
arrange.source_sqlite <- function(.data, ...) {
  input <- partial_eval(.data, dots(...), parent.frame())
  .data$arrange <- c(.data$arrange, input)
  .data
}

#' @rdname manip_sqlite
#' @export
#' @method select source_sqlite
select.source_sqlite <- function(.data, ...) {
  input <- var_eval(.data, dots(...), parent.frame())
  .data$select <- c(.data$select, input)
  .data
}

#' @rdname manip_sqlite
#' @export
#' @method summarise source_sqlite
summarise.source_sqlite <- function(.data, ..., .n = 1e5) {
  assert_that(length(.n) == 1, .n > 0L)
  if (!is.null(.data$select)) {
    warning("Summarise ignores selected variables", call. = FALSE)
  }

  select <- translate_sql_q(dots(...), .data, parent.frame())
  out <- sql_select(.data, select = select, n = .n)
  data_frame_source(
    data = out,
    name = .data$table
  )
}

#' @rdname manip_sqlite
#' @export
#' @method mutate source_sqlite
mutate.source_sqlite <- function(.data, ..., .n = 1e5) {
  assert_that(length(.n) == 1, .n > 0L)

  old_vars <- .data$select %||% "*"
  new_vars <- translate_sql_q(dots(...), .data, parent.frame())

  out <- sql_select(.data, select = c(old_vars, new_vars), n = .n)
  data_frame_source(
    data = out,
    name = .data$table
  )
}