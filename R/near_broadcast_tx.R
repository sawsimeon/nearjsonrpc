#' Broadcast a Signed Transaction to the NEAR Network
#'
#' Sends a pre-signed transaction (base64-encoded) using the `send_tx` RPC method.
#' Supports different wait levels from instant hash to full finality.
#'
#' @param signed_tx_base64 Character scalar. Base64-encoded signed transaction.
#'   Generate with `near-cli` or near-api-js.
#' @param wait_until How long to wait for outcome:
#'   - `"NONE"` — return hash immediately
#'   - `"INCLUDED"` — wait for block inclusion
#'   - `"INCLUDED_FINAL"` — wait for finalization
#'   - `"EXECUTED_OPTIMISTIC"` — wait for execution (default)
#'   - `"FINAL"` — wait for final outcome (safest)
#'
#' @return tibble with hash, status, receipts, and raw response.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # === SAFE TESTNET EXAMPLE USING sawsimeon.testnet ===
#'
#' # 1. Generate signed transaction with near-cli (harmless view call)
#' # Run in terminal:
#' # near call wrap.testnet ft_metadata '{}' --accountId sawsimeon.testnet --signWithOfflineKeyPair
#'
#' # near-cli will output a base64 string like:
#' tx_hash <- "6CzRJwPqcAufsTztarbtG3wbAzeV6XRGVQvmSDQWvdXo"
#'
#' near_set_endpoint("testnet")
#' result <- near_get_transaction_status(tx_hash = tx_hash, sender_account_id = sender, wait_until = "FINAL")
#' result
#' }
#'
#' @seealso
#' \url{https://docs.near.org/tools/near-cli#sign-transaction}
#' [near_get_transaction_status()] – poll later
#'
near_broadcast_tx <- function(
    signed_tx_base64,
    wait_until = c("EXECUTED_OPTIMISTIC", "NONE", "INCLUDED", "INCLUDED_FINAL", "FINAL")
) {
  if (missing(signed_tx_base64) || !is.character(signed_tx_base64) || length(signed_tx_base64) != 1 || !nzchar(signed_tx_base64)) {
    rlang::abort("`signed_tx_base64` must be a non-empty base64 string")
  }

  wait_until <- match.arg(wait_until)

  payload <- list(
    jsonrpc = "2.0",
    id = "nearjsonrpc",
    method = "send_tx",
    params = list(
      signed_tx_base64 = signed_tx_base64,
      wait_until       = wait_until
    )
  )

  endpoint <- getOption("nearjsonrpc.endpoint", "https://rpc.testnet.near.org")

  resp <- httr2::request(endpoint) %>%
    httr2::req_headers("Content-Type" = "application/json") %>%
    httr2::req_body_json(payload) %>%
    httr2::req_perform()

  out <- httr2::resp_body_json(resp)

  # "NONE" returns just the hash as string
  if (is.character(out) && length(out) == 1) {
    return(tibble::tibble(hash = out))
  }

  # Full result
  tibble::tibble(
    hash           = out$transaction_hash %||% NA_character_,
    status         = list(out$status %||% list()),
    transaction    = list(out$transaction %||% list()),
    receipts       = list(out$receipts %||% list()),
    raw_response   = list(out)
  )
}
