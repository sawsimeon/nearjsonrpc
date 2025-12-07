#' Get a block from NEAR
#'
#' Retrieve a block using the `block` method. Provide either `finality` or `block_id`.
#'
#' @param finality Character scalar. One of "final" or "optimistic". Defaults to "final".
#' @param block_id Character or integer. Block height (integer) or block hash (string).
#' @return A tibble with header (as a list-column) and chunks (list-column). Header fields are available inside header.
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_get_block(finality = "final")
#' near_get_block(block_id = 1234567)
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/blocks}
#' @export
near_get_block <- function(finality = "final", block_id = NULL) {
  if (!is.null(block_id) && !missing(finality)) {
    rlang::abort("Specify either finality or block_id, not both")
  }

  params <- list()
  if (!is.null(block_id)) params$block_id <- block_id else params$finality <- finality

  resp <- near_rpc("block", params = params)
  res <- if (!is.null(resp$result)) resp$result else resp

  if (!is.list(res)) rlang::abort("Unexpected response format from RPC")

  t <- tibble::tibble(
    header = list(res$header %||% list()),
    chunks = list(res$chunks %||% list())
  )
  return(t)
}
