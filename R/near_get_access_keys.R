#' List Access Keys for a NEAR Account
#'
#' Retrieves all access keys (full access + function call keys) associated with a NEAR account.
#' Uses the `query` RPC method with `request_type = "view_access_key_list"`.
#'
#' @param account_id Character scalar. The account ID to query (e.g., `"alice.near"`, `"bob.testnet"`).
#' @param finality Character. Block finality: `"final"` (default, safest) or `"optimistic"` (faster).
#' @param block_id Integer or character. Optional specific block height or hash. Cannot be used together with `finality`.
#'
#' @return A tibble with one row per access key:
#'   \item{public_key}{Ed25519 public key in base58 format (e.g., `"ed25519:8z..."`)}
#'   \item{access_key}{List-column containing permission details:}
#'     \itemize{
#'       \item `nonce` – current nonce
#'       \item `permission` – either `"FullAccess"` or a `FunctionCall` object with `allowance`, `receiver_id`, `method_names`
#'     }
#'   \item{block_height, block_hash}{context of the query}
#'   \item{raw_response}{full RPC response for debugging}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Set endpoint first
#' near_set_endpoint("mainnet")
#'
#' # 1. List all keys for an account
#' keys <- near_get_access_keys("vitalik.near")
#' keys
#'
#' # View only full-access keys
#' keys |> dplyr::filter(access_key == "FullAccess")
#'
#' # View function-call keys (e.g. limited to a specific contract)
#' keys |>
#'   tidyr::unnest_wider(access_key) |>
#'   dplyr::select(public_key, receiver_id, method_names)
#'
#' # 2. Check your own testnet account
#' near_set_endpoint("testnet")
#' near_get_access_keys("sawsimeon.testnet")
#'
#' # 3. Historical view — what keys existed at block 90,000,000?
#' near_get_access_keys("bowen.testnet", block_id = 90000000)
#' }
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/access-keys#view-access-key-list}
#' \url{https://docs.near.org/concepts/basics/accounts/access-keys}
#' [near_query_account()] – to get account state including nonce
#'
near_get_access_keys <- function(
    account_id,
    finality = c("final", "optimistic"),
    block_id = NULL
) {
  # ── Input validation ─────────────────────────────────────────────────────
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1 || !nzchar(account_id)) {
    rlang::abort("`account_id` must be a non-empty character string")
  }

  if (!is.null(block_id) && !missing(finality)) {
    rlang::abort("Use either `finality` OR `block_id`, not both")
  }

  finality <- match.arg(finality)

  # ── build params ───────────────────────────────────────────────────────
  params <- list(
    request_type = "view_access_key_list",
    account_id   = account_id
  )

  if (!is.null(block_id)) {
    params$block_id <- block_id
  } else {
    params$finality <- finality
  }

  # ── call RPC ───────────────────────────────────────────────────────────
  resp <- near_rpc("query", params = params)

  res <- resp$result %||% resp
  if (is.null(res) || !is.list(res)) {
    rlang::abort("Invalid or empty response from RPC — account may not exist")
  }

  keys <- res$keys %||% list()
  n <- length(keys)

  if (n == 0) {
    return(tibble::tibble(
      public_key   = character(),
      access_key   = list(),
      block_height = integer(),
      block_hash   = character(),
      raw_response = list()
    ))
  }

  # Extract public keys
  public_keys <- vapply(keys, function(k) k$public_key %||% NA_character_, character(1))

  # Extract access_key details (preserve structure)
  access_keys <- lapply(keys, function(k) k$access_key %||% list())

  tibble::tibble(
    public_key   = public_keys,
    access_key   = access_keys,
    block_height = res$block_height %||% NA_integer_,
    block_hash   = res$block_hash %||% NA_character_,
    raw_response = list(resp)
  )
}
