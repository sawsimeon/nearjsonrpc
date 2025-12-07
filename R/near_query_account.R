#' Query Account Details and Balance
#'
#' Retrieves full account state including balance, storage usage, and code hash.
#'
#' @param account_id Character scalar. Account to query.
#' @param finality `"final"` (default) or `"optimistic"`.
#' @param block_id Optional block height or hash.
#'
#' @return A tibble with account details (amount in yoctoNEAR, etc.).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' near_set_endpoint("mainnet")
#' near_query_account("vitalik.near")
#' near_query_account("near")
#' }
#'
#' @seealso \url{https://docs.near.org/api/rpc/contracts#view-account}
#'
near_query_account <- function(account_id, finality = "final", block_id = NULL) {
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1) {
    rlang::abort("`account_id` must be a single string")
  }

  params <- list(
    request_type = "view_account",
    account_id   = account_id
  )
  if (!is.null(block_id)) params$block_id <- block_id else params$finality <- finality

  resp <- near_rpc("query", params)

  res <- resp$result %||% resp
  tibble::tibble(
    account_id      = res$account_id %||% account_id,
    amount          = as.character(res$amount %||% "0"),
    locked          = as.character(res$locked %||% "0"),
    storage_usage   = res$storage_usage %||% NA_integer_,
    code_hash       = res$code_hash %||% NA_character_,
    block_height    = res$block_height %||% NA_integer_,
    block_hash      = res$block_hash %||% NA_character_,
    raw_response    = list(resp)
  )
}
