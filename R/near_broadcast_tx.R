# R/near_broadcast_tx.R

#' Broadcast a Signed Transaction to the NEAR Network
#'
#' Sends a pre-signed transaction using the `send_tx` RPC method.
#' Supports different wait levels for outcome confirmation.
#'
#' @param signed_tx_base64 Character scalar. Base64-encoded signed transaction.
#'   Generate with `near-cli` using `--signWithOfflineKeyPair`.
#' @param wait_until Character. How long to wait for result:
#'   - `"NONE"` — return hash immediately (fastest)
#'   - `"INCLUDED"` — wait for block inclusion
#'   - `"INCLUDED_FINAL"` — wait for finalization
#'   - `"EXECUTED_OPTIMISTIC"` — wait for execution (default)
#'   - `"FINAL"` — wait for final outcome (safest)
#'
#' @return A tibble with:
#'   - `hash`: transaction hash
#'   - `status`: execution outcome (list-column)
#'   - `transaction`: transaction details
#'   - `receipts`: receipt outcomes
#'   - `raw_response`: full response for debugging
#'
#'   For `wait_until = "NONE"`, only `hash` is returned.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # === SAFE TESTNET EXAMPLE USING sawsimeon.testnet ===
#'
#' # 1. Generate a harmless signed transaction (view call)
#' # Run in terminal:
#' # near call wrap.testnet ft_metadata '{}' \
#' #   --accountId sawsimeon.testnet \
#' #   --signWithOfflineKeyPair
#'
#' # near-cli will print a long base64 string — copy it
#' signed_tx_b64 <- "YOUR_BASE64_STRING_HERE"
#'
#' near_set_endpoint("testnet")
#'
#' # Broadcast and get only hash (fast)
#' near_broadcast_tx(signed_tx_b64, wait_until = "NONE")
#' # Returns tibble with just the hash
#'
#' # Wait for full execution and outcome
#' result <- near_broadcast_tx(signed_tx_b64, wait_until = "EXECUTED_OPTIMISTIC")
#' result
#' result$hash
#' result$status[[1]]$SuccessValue  # if function call returned value
#'
#' # Wait for finality (strongest guarantee)
#' near_broadcast_tx(signed_tx_b64, wait_until = "FINAL")
#' }
#'
#' @seealso
#' \url{https://docs.near.org/tools/near-cli#sign-transaction}
#' \url{https://docs.near.org/api/rpc/transactions#send-transaction-wait-until}
#' [near_get_transaction_status()] – check status later
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

  # "NONE" returns just the hash as a string
  if (is.character(out) && length(out) == 1) {
    return(tibble::tibble(hash = out))
  }

  # Full result (all other wait_until values)
  tibble::tibble(
    hash           = out$transaction$hash %||% out$transaction_hash %||% NA_character_,
    status         = list(out$status %||% list()),
    transaction    = list(out$transaction %||% list()),
    receipts       = list(out$receipts %||% list()),
    raw_response   = list(out)
  )
}
