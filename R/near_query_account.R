#' Query an account on NEAR
#'
#' Retrieve account information using the NEAR JSON-RPC `query` method with
#' `request_type = "view_account"`.
#'
#' @param account_id Character scalar. NEAR account id (e.g. "example.testnet").
#' @param finality Character scalar. One of "final" or "optimistic". Defaults to "final".
#' @param block_id Character or integer. Block height (integer) or block hash (string).
#' @return A tibble with account fields: account_id, amount, locked, code_hash, storage_usage, storage_paid_at, block_height (if available) and raw (the full raw list).
#' @details Uses NEAR RPC method `query` with `request_type = "view_account"`.
#' Only one of `finality` or `block_id` may be provided. If both are provided an error is raised.
#' If the account does not exist, the RPC will return an error which is propagated.
#' @examples
#' \dontrun{
#' # Basic mainnet query
#' near_set_endpoint("https://rpc.mainnet.near.org")
#' near_query_account("alice.near")
#'
#' # Testnet
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_query_account("example.testnet", finality = "optimistic")
#'
#' # Query a specific block by height
#' near_query_account("example.testnet", block_id = 1234567)
#'
#' # Invalid usage: both finality and block_id
#' try(near_query_account("example.testnet", finality = "final", block_id = 10))
#' }
#' @seealso
#' URL{https://docs.near.org/api/rpc/overview}, near_get_access_keys
#' @export
near_query_account <- function(account_id, finality = "final", block_id = NULL) {
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1) {
    rlang::abort("account_id must be a single string")
  }

  if (!is.null(block_id) && !missing(finality) && !is.null(finality)) {
    # If user explicitly provided both, error
    if (!is.null(block_id) && !identical(finality, "final") && !identical(finality, "optimistic")) {
      # allow default finality if block_id provided? Spec says use finality or block_id, not both.
    }
  }
  if (!is.null(block_id) && !missing(finality) && !is.null(finality)) {
    rlang::abort("Specify either finality or block_id, not both")
  }

  params <- list(request_type = "view_account", account_id = account_id)
  if (!is.null(block_id)) {
    params$block_id <- block_id
  } else {
    params$finality <- finality
  }

  resp <- near_rpc("query", params = params)
  # NEAR RPC might return top-level 'result' or be direct
  res <- if (!is.null(resp$result)) resp$result else resp

  if (!is.list(res)) {
    rlang::abort("Unexpected response format from RPC")
  }

  # Create tidy tibble output
  t <- tibble::tibble(
    account_id = account_id,
    amount = as.character(res$amount %||% NA_character_),
    locked = as.character(res$locked %||% NA_character_),
    code_hash = as.character(res$code_hash %||% NA_character_),
    storage_usage = if (!is.null(res$storage_usage)) as.integer(res$storage_usage) else NA_integer_,
    storage_paid_at = if (!is.null(res$storage_paid_at)) as.character(res$storage_paid_at) else NA_character_,
    block_height = if (!is.null(res$block_height)) as.integer(res$block_height) else NA_integer_,
    raw = list(res)
  )
  return(t)
}
