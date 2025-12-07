#' Broadcast a Signed Transaction to the NEAR Network
#'
#' Sends a pre-signed transaction (in base64 format) to the NEAR blockchain using
#' the modern `send_tx` JSON-RPC method (replaces the deprecated `broadcast_tx_async/commit`).
#'
#' @param signed_tx_base64 Character scalar. A fully signed transaction encoded as base64.
#'   Typically created using `nearapi` or `near-cli` with `near transaction sign ...`.
#' @param wait_until Character scalar controlling how long the node waits before returning.
#'   Valid options:
#'   - `"NONE"` – returns immediately with only the transaction hash
#'   - `"INCLUDED"` – waits until included in a block
#'   - `"INCLUDED_FINAL"` – waits until included in a finalized block
#'   - `"EXECUTED_OPTIMISTIC"` – waits until execution (default, recommended)
#'   - `"FINAL"` – waits until finality (strongest guarantee)
#'
#' @return A tibble with one row containing:
#'   - `hash`: transaction hash (character)
#'   - `status`: execution outcome (list-column)
#'   - `transaction`: original transaction object (list-column)
#'   - `receipts`: array of receipt outcomes (list-column)
#'   - `raw`: full raw JSON response (list-column, useful for debugging)
#'
#'   If `wait_until = "NONE"`, only `hash` is returned.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # 1. Real example using near-cli generated signed tx (testnet)
#' signed_tx <- "aGVsbG8gd29ybGQ..."  # your actual base64 string from near-cli
#'
#' near_set_endpoint("testnet")
#'
#' # Quick fire-and-forget
#' near_broadcast_tx(signed_tx, wait_until = "NONE")
#' #> # A tibble: 1 × 1
#' #>   hash
#' #>   <chr>
#' #> 1 Cj3k...examplehash
#'
#' # Wait for execution (recommended for most apps)
#' result <- near_broadcast_tx(signed_tx, wait_until = "EXECUTED_OPTIMISTIC")
#' result
#' result$status[[1]]$SuccessValue  # view return value if function call
#'
#' # Wait for finality (for critical operations)
#' final <- near_broadcast_tx(signed_tx, wait_until = "FINAL")
#' final$receipts
#' }
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/transactions#send-transaction-wait-until}
#' \url{https://docs.near.org/tools/near-cli#sign-transaction}
#' [near_get_transaction_status()] – to poll a transaction later
#'
near_broadcast_tx <- function(
    signed_tx_base64,
    wait_until = c("EXECUTED_OPTIMISTIC", "NONE", "INCLUDED", "INCLUDED_FINAL", "FINAL")
) {
  # Input validation
  if (missing(signed_tx_base64) || !is.character(signed_tx_base64) || length(signed_tx_base64) != 1 || !nzchar(signed_tx_base64)) {
    rlang::abort("`signed_tx_base64` must be a non-empty character scalar containing a valid base64 string")
  }

  wait_until <- match.arg(wait_until)

  params <- list(
    signed_tx_base64 = signed_tx_base64,
    wait_until       = wait_until
  )

  resp <- near_rpc("send_tx", params = params)

  # Case 1: wait_until = "NONE" → node returns just the hash as string
  if (is.character(resp) && length(resp) == 1) {
    return(tibble::tibble(hash = resp))
  }

  # Case 2: Full result object
  tibble::tibble(
    hash         = resp$transaction_hash %||% resp$transaction?.hash %||% NA_character_,
    status       = list(resp$status %||% list()),
    transaction  = list(resp$transaction %||% list()),
    receipts     = list(resp$receipts %||% list()),
    raw_response = list(resp)
  )
}
