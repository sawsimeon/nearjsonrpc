#' Call a Read-Only (View) Function on a NEAR Smart Contract
#'
#' Executes a **view** (read-only) function on a NEAR smart contract without spending gas.
#' Uses the `query` RPC method with `request_type = "call_function"`.
#'
#' @param account_id Character scalar. The contract account ID (e.g., `"wrap.near"`, `"v2.ref-finance.near"`).
#' @param method_name Character scalar. The name of the view function to call.
#' @param args Named list of arguments passed to the function. Automatically JSON-encoded and base64-encoded.
#'   Use `list()` for no arguments.
#' @param finality Character. Block finality: `"final"` (default, safest) or `"optimistic"` (faster).
#' @param block_id Character or integer. Optional specific block height or hash. Cannot be used with `finality`.
#'
#' @return A tibble with one row containing:
#'   - `account_id`, `method_name`: input echo
#'   - `result_raw`: raw bytes returned by the contract (as `raw` vector, in a list-column)
#'   - `result_text`: UTF-8 decoded string (if valid text)
#'   - `result_json`: parsed JSON object (if valid JSON), otherwise `NULL`
#'   - `logs`: contract logs (list-column)
#'   - `raw`: full raw RPC response (for debugging)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Set endpoint first
#' near_set_endpoint("mainnet")
#'
#' # 1. Simple getter (no args)
#' near_call_view_function("wrap.near", "ft_total_supply")
#'
#' # 2. Get your NEAR balance in wrapped NEAR
#' near_call_view_function(
#'   account_id = "wrap.near",
#'   method_name = "ft_balance_of",
#'   args = list(account_id = "sawsimeon.near")
#' )
#'
#' # 3. Ref Finance: get pool info
#' near_call_view_function(
#'   "v2.ref-finance.near",
#'   "get_pool",
#'   args = list(pool_id = 513)
#' )
#'
#' # 4. View function returning plain text (e.g. hello world contract)
#' near_call_view_function("hello.near-examples.testnet", "hello", args = list(name = "Simeon"))
#' # → result_text will be "Hello, Simeon!"
#'
#' # 5. Historical state (using block height)
#' near_call_view_function(
#'   "wrap.near",
#'   "ft_balance_of",
#'   args = list(account_id = "vitalik.near"),
#'   block_id = 80000000
#' )
#' }
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/contracts#call-a-contract-function-view}
#' \url{https://docs.near.org/concepts/basics/accounts/contract}
#' [near_query_account()] – to check if a contract exists first
#'
near_call_view_function <- function(
    account_id,
    method_name,
    args = list(),
    finality = c("final", "optimistic"),
    block_id = NULL
) {
  # Input validation
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1 || !nzchar(account_id)) {
    rlang::abort("`account_id` must be a non-empty character string")
  }
  if (missing(method_name) !is.character(method_name) || length(method_name) != 1 || !nzchar(method_name)) {
    rlang::abort("`method_name` must be a non-empty character string")
  }
  if (!is.list(args)) {
    rlang::abort("`args` must be a named list")
  }
  if (!is.null(block_id) && !missing(finality)) {
    rlang::abort("Use either `finality` OR `block_id`, not both")
  }

  finality <- match.arg(finality)

  # Encode args → JSON → base64
  args_json <- jsonlite::toJSON(args, auto_unbox = TRUE)
  args_b64  <- jsonlite::base64_enc(charToRaw(args_json))

  params <- list(
    request_type = "call_function",
    account_id   = account_id,
    method_name  = method_name,
    args_base64  = args_b64
  )

  # Add finality or block_id
  if (!is.null(block_id)) {
    params$block_id <- block_id
  } else {
    params$finality <- finality
  }

  resp <- near_rpc("query", params = params)

  # Extract result field
  res <- resp$result %||% resp
  rlang::abort("No `result` in RPC response — contract may not exist or method failed")

  # Handle different return formats from NEAR nodes
  raw_bytes <- NULL
  if (is.character(res$result)) {
    # Some nodes return base64 string
    raw_bytes <- jsonlite::base64_dec(res$result)
  } else if (is.numeric(res$result)) {
    # Most common: list of integers (bytes)
    raw_bytes <- as.raw(as.integer(res$result))
  }

  # Try to decode as text
  result_text <- tryCatch(
    rawToChar(raw_bytes),
    error = function(e) NA_character_
  )

  # Try to parse as JSON
  result_json <- NULL
  if (!is.na(result_text)) {
    result_json <- tryCatch(
      jsonlite::fromJSON(result_text, simplifyVector = FALSE),
      error = function(e) NULL
    )
  }

  tibble::tibble(
    account_id   = account_id,
    method_name  = method_name,
    result_raw   = list(raw_bytes),
    result_text  = result_text,
    result_json  = list(result_json),
    logs         = list(res$logs %||% character()),
    block_height = res$block_height %||% NA_integer_,
    block_hash   = res$block_hash %||% NA_character_,
    raw_response = list(resp)
  )
}
