#' Check Transaction Status and Outcome
#'
#' @param tx_hash Transaction hash (base58).
#' @param sender_account_id Account that sent the transaction.
#' @param wait_until Wait level (defaults to `"EXECUTED_OPTIMISTIC"`).
#'
#' @return Detailed outcome tibble.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' near_get_transaction_status("Cj3k...xyz", "alice.near")
#' }
#'
#' @seealso \url{https://docs.near.org/api/rpc/transactions#transaction-status}
#'
near_get_transaction_status <- function(tx_hash, sender_account_id, wait_until = "EXECUTED_OPTIMISTIC") {
  params <- list(
    tx_hash = tx_hash,
    sender_account_id = sender_account_id,
    wait_until = toupper(wait_until)
  )

  resp <- near_rpc("tx", params)
  res <- resp$result %||% resp

  tibble::tibble(
    hash = tx_hash,
    status = list(res$status %||% list()),
    transaction = list(res$transaction %||% list()),
    receipts_outcome = list(res$receipts_outcome %||% list()),
    raw_response = list(resp)
  )
}
