#' Get access keys for an account
#'
#' Uses `query` with `request_type = "view_access_key_list"` to list access keys.
#'
#' @param account_id Character scalar. Account id to query.
#' @param finality Character scalar. One of "final" or "optimistic". Defaults to "final".
#' @param block_id Character or integer. Optional block id.
#' @return A tibble with public_key and access_key (list-column), and raw.
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_get_access_keys("example.testnet")
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/key-access}
#' @export
near_get_access_keys <- function(account_id, finality = "final", block_id = NULL) {
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1) rlang::abort("account_id must be a single string")
  if (!is.null(block_id) && !missing(finality)) rlang::abort("Specify either finality or block_id, not both")

  params <- list(request_type = "view_access_key_list", account_id = account_id)
  if (!is.null(block_id)) params$block_id <- block_id else params$finality <- finality

  resp <- near_rpc("query", params = params)
  res <- if (!is.null(resp$result)) resp$result else resp
  if (!is.list(res)) rlang::abort("Unexpected response format from RPC")

  keys <- res$keys %||% list()
  if (length(keys) == 0) return(tibble::tibble(public_key = character(), access_key = list(), raw = list()))

  pub <- vapply(keys, function(k) k$public_key %||% NA_character_, character(1))
  acc <- lapply(keys, function(k) k$access_key %||% list())

  t <- tibble::tibble(public_key = pub, access_key = acc, raw = list(res))
  return(t)
}
