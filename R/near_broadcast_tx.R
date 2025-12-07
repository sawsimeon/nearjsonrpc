#' Send a signed transaction to NEAR
#'
#' Uses the `send_tx` RPC method to broadcast a signed transaction base64.
#'
#' @param signed_tx_base64 Character scalar containing the signed transaction encoded in base64.
#' @param wait_until Character scalar controlling waiting behavior. One of "NONE", "INCLUDED", "INCLUDED_FINAL", "EXECUTED_OPTIMISTIC", "FINAL". Defaults to "EXECUTED_OPTIMISTIC".
#' @return A tibble. For NONE returns hash-only tibble; for other wait options returns detailed outcome(s) in list-columns.
#' @examples
#' \dontrun{
#' # Example (dummy signed tx)
#' tx_b64 <- "BASE64SIGNEDTX"
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_broadcast_tx(tx_b64, wait_until = "INCLUDED_FINAL")
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/transactions}
#' @export
near_broadcast_tx <- function(signed_tx_base64, wait_until = "EXECUTED_OPTIMISTIC") {
  if (missing(signed_tx_base64) || !is.character(signed_tx_base64) || length(signed_tx_base64) != 1) {
    rlang::abort("signed_tx_base64 must be a single base64 string")
  }
  valid <- c("NONE", "INCLUDED", "INCLUDED_FINAL", "EXECUTED_OPTIMISTIC", "FINAL")
  if (!toupper(wait_until) %in% valid) rlang::abort("wait_until must be one of: ", paste(valid, collapse = ", "))

  params <- list(signed_tx_base64 = signed_tx_base64, wait_until = toupper(wait_until))
  resp <- near_rpc("send_tx", params = params)
  res <- if (!is.null(resp$result)) resp$result else resp

  # If resp is just a hash
  if (is.character(res) && length(res) == 1) {
    return(tibble::tibble(hash = res))
  }

  # Otherwise return tibble with details
  t <- tibble::tibble(
    hash = if (!is.null(res$transaction_hash)) as.character(res$transaction_hash) else NA_character_,
    status = list(res$status %||% list()),
    transaction = list(res$transaction %||% list()),
    receipts = list(res$receipts %||% list()),
    raw = list(res)
  )
  return(t)
}
