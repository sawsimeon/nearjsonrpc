#' Get transaction status
#'
#' Calls the `tx` RPC method to fetch a transaction's status and outcomes.
#'
#' @param tx_hash Character scalar. Transaction hash as hex string.
'#' @param sender_account_id Character scalar. The account id of the sender.
#' @param wait_until Character scalar controlling waiting behavior. One of "NONE", "INCLUDED", "INCLUDED_FINAL", "EXECUTED_OPTIMISTIC", "FINAL". Defaults to "EXECUTED_OPTIMISTIC".
#' @return A tibble with transaction hash, status, transaction, receipts, raw.
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_get_transaction_status("txhashhex", "example.testnet")
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/transactions}
#' @export
near_get_transaction_status <- function(tx_hash, sender_account_id, wait_until = "EXECUTED_OPTIMISTIC") {
  if (missing(tx_hash) || !is.character(tx_hash) || length(tx_hash) != 1) rlang::abort("tx_hash must be a single string")
  if (missing(sender_account_id) || !is.character(sender_account_id) || length(sender_account_id) != 1) rlang::abort("sender_account_id must be a single string")

  valid <- c("NONE", "INCLUDED", "INCLUDED_FINAL", "EXECUTED_OPTIMISTIC", "FINAL")
  if (!toupper(wait_until) %in% valid) rlang::abort("wait_until must be one of: ", paste(valid, collapse = ", "))

  params <- list(tx_hash = tx_hash, sender_account_id = sender_account_id, wait_until = toupper(wait_until))
  resp <- near_rpc("tx", params = params)
  res <- if (!is.null(resp$result)) resp$result else resp

  if (is.character(res) && length(res) == 1) {
    # sometimes direct string
    return(tibble::tibble(tx_hash = res))
  }

  t <- tibble::tibble(
    tx_hash = if (!is.null(res$transaction_hash)) as.character(res$transaction_hash) else as.character(tx_hash),
    status = list(res$status %||% list()),
    transaction = list(res$transaction %||% list()),
    receipts = list(res$receipts %||% list()),
    raw = list(res)
  )
  return(t)
}
