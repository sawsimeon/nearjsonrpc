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
#'
#' # Generate a signed transaction using near-cli (harmless view call):
#' # In your terminal run:
#' # near call wrap.testnet ft_metadata \'{}\' \
#' #   --accountId sawsimeon.testnet \
#' #   --signWithOfflineKeyPair
#'
#' # Copy the printed base64 string and paste below:
#' signed_tx_b64 <- "YOUR_BASE64_STRING_FROM_NEAR_CLI"
#'
#' near_set_endpoint("testnet")
#'
#' # Get only the hash (fast)
#' near_broadcast_tx(signed_tx_b64, wait_until = "NONE")
#'
#' # Wait for full execution
#' result <- near_broadcast_tx(signed_tx_b64, wait_until = "EXECUTED_OPTIMISTIC")
#' result$hash
#' result$status[[1]]
#'
#' # Wait for finality
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

  # Full result
  tibble::tibble(
    hash           = out$transaction$hash %||% out$transaction_hash %||% NA_character_,
    status         = list(out$status %||% list()),
    transaction    = list(out$transaction %||% list()),
    receipts       = list(out$receipts %||% list()),
    raw_response   = list(out)
  )
}
