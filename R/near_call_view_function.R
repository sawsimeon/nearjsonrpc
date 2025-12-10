#' Call a Read-Only View Function on a NEAR Smart Contract
#'
#' Executes a contract view method and returns decoded text + parsed JSON.
#' Works perfectly with `wrap.near`, `ref-finance`, and all NEP-141 tokens.
#'
#' @param account_id Character. Contract account (e.g. `"wrap.near"`).
#' @param method_name Character. Method to call (e.g. `"ft_metadata"`).
#' @param args Named list of arguments. Use `list()` for no args.
#' @param finality `"final"` (default) or `"optimistic"`.
#' @param block_id Optional block height or hash (overrides finality).
#'
#' @return A tibble with:
#'   \item{result_raw}{raw bytes}
#'   \item{result_text}{UTF-8 decoded string}
#'   \item{result_json}{parsed JSON (or `NULL` if not JSON)}
#'   \item{logs, block_height, block_hash, raw_response}{metadata}
#'
#' @export
#'
#' @examples
#' near_set_endpoint("mainnet")
#'
#' # FT Metadata
#' near_call_view_function("wrap.near", "ft_metadata")$result_json[[1]]
#'
#' # Total supply
#' near_call_view_function("wrap.near", "ft_total_supply")$result_text
#'
#' # Balance query — REQUIRED argument!
#' near_call_view_function(
#'   "wrap.near",
#'   "ft_balance_of",
#'   args = list(account_id = "vitalik.near")
#' )$result_text
#'
#' # Ref Finance pool info
#' near_call_view_function(
#'   "v2.ref-finance.near",
#'   "get_pool",
#'   args = list(pool_id = 513)
#' )
#'
#' # Historical call
#' near_call_view_function(
#'   "wrap.near",
#'   "ft_balance_of",
#'   args = list(account_id = "vitalik.near"),
#'   block_id = 80000000
#' )
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/contracts#call-a-contract-function-view}
#'
near_call_view_function <- function(
    account_id,
    method_name,
    args = list(),
    finality = "final",
    block_id = NULL
) {
  stopifnot(is.character(account_id), length(account_id) == 1, nzchar(account_id))
  stopifnot(is.character(method_name), length(method_name) == 1, nzchar(method_name))
  stopifnot(is.list(args))

  # Encode empty args correctly → "{}" → "e30="
  args_json <- jsonlite::toJSON(args, auto_unbox = TRUE)
  args_b64 <- jsonlite::base64_enc(charToRaw(args_json))

  # Build params exactly like your working code
  params <- list(
    request_type = "call_function",
    account_id   = account_id,
    method_name  = method_name,
    args_base64  = args_b64
  )

  if (!is.null(block_id)) {
    params$finality <- NULL
    params$block_id <- block_id
  } else {
    params$finality <- finality
  }

  # === Use your exact working payload structure ===
  payload <- list(
    jsonrpc = "2.0",
    id = "nearjsonrpc",
    method = "query",
    params = params
  )

  endpoint <- getOption("nearjsonrpc.endpoint", "https://rpc.mainnet.near.org")

  resp <- httr2::request(endpoint) %>%
    httr2::req_headers("Content-Type" = "application/json") %>%
    httr2::req_body_json(payload) %>%
    httr2::req_perform()

  out <- httr2::resp_body_json(resp)

  # Extract result bytes — your proven path
  raw_bytes <- as.raw(out$result$result)
  result_text <- rawToChar(raw_bytes)
  result_json <- jsonlite::fromJSON(result_text, simplifyVector = FALSE)

  tibble::tibble(
    account_id   = account_id,
    method_name  = method_name,
    result_raw   = list(raw_bytes),
    result_text  = result_text,
    result_json  = list(result_json),
    logs         = list(out$result$logs %||% character()),
    block_height = out$result$block_height %||% NA_integer_,
    block_hash   = out$result$block_hash %||% NA_character_,
    raw_response = list(out)
  )
}
