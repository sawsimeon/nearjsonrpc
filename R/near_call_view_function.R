#' Call a Read-Only (View) Function on a NEAR Smart Contract
#'
#' Executes a **view** (read-only) function on a NEAR smart contract without spending gas.
#' Uses the `query` RPC method with `request_type = "call_function"`.
#'
#' @param account_id Character scalar. The contract account ID (e.g. `"wrap.near"`).
#' @param method_name Character scalar. Name of the view function.
#' @param args Named list of arguments (automatically JSON-encoded to base64). Use `list()` for no arguments.
#' @param finality Block finality: `"final"` (default & safest) or `"optimistic"` (faster).
#' @param block_id Optional specific block height (integer) or hash (character). Cannot be used together with `finality`.
#'
#' @return A tibble with one row containing:
#'   \item{account_id, method_name}{echo of inputs}
#'   \item{result_raw}{raw bytes as `raw` vector (list-column)}
#'   \item{result_text}{UTF-8 decoded string (or `NA`)}
#'   \item{result_json}{parsed JSON object (or `NULL` if not valid JSON)}
#'   \item{logs}{contract logs}
#'   \item{block_height, block_hash}{context of the call}
#'   \item{raw_response}{complete RPC response for debugging}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' near_set_endpoint("mainnet")
#'
#' # Simple getter
#' near_call_view_function("wrap.near", "ft_total_supply")
#'
#' # With arguments
#' near_call_view_function(
#'   "wrap.near",
#'   "ft_balance_of",
#'   args = list(account_id = "sawsimeon.near")
#' )
#'
#'
#' # Ref Finance example
#' near_call_view_function("v2.ref-finance.near", "get_pool", args = list(pool_id = 513))
#'
#' # Historical view at a specific block
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
#'
near_call_view_function <- function(
    account_id,
    method_name,
    args = list(),
    finality = c("final", "optimistic"),
    block_id = NULL
) {
  #  Input validation
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1 || !nzchar(account_id)) {
    rlang::abort("`account_id` must be a non-empty character string")
  }

  if (missing(method_name) || !is.character(method_name) || length(method_name) != 1 || !nzchar(method_name)) {
    rlang::abort("`method_name` must be a non-empty character string")
  }

  if (!is.list(args)) {
    rlang::abort("`args` must be a list")
  }

  if (!is.null(block_id) && !missing(finality)) {
    rlang::abort("Specify either `finality` OR `block_id`, not both")
  }

  finality <- match.arg(finality)

  #  Encode arguments
  args_json <- jsonlite::toJSON(args, auto_unbox = TRUE)
  args_b64  <- jsonlite::base64_enc(charToRaw(args_json))

  #  Build RPC parameters
  params <- list(
    request_type = "call_function",
    account_id   = account_id,
    method_name  = method_name,
    args_base64  = args_b64
  )

  if (!is.null(block_id)) {
    params$block_id <- block_id
  } else {
    params$finality <- finality
  }

  #  Perform RPC call
  resp <- near_rpc("query", params = params)

  #  Extract result
  res <- resp$result %||% resp
  if (is.null(res)) {
    rlang::abort("No `result` field in RPC response — contract or method may not exist")
  }

  # Handle the two formats NEAR nodes can return
  raw_bytes <- NULL
  if (is.character(res$result)) {
    raw_bytes <- jsonlite::base64_dec(res$result)
  } else if (is.numeric(res$result)) {
    raw_bytes <- as.raw(as.integer(res$result))
  }

  # Decode as text
  result_text <- tryCatch(rawToChar(raw_bytes), error = function(e) NA_character_)

  # Try to parse JSON
  result_json <- NULL
  if (!is.na(result_text)) {
    result_json <- tryCatch(
      jsonlite::fromJSON(result_text, simplifyVector = FALSE),
      error = function(e) NULL
    )
  }

  #  Return tidy tibble
  tibble::tibble(
    account_id    = account_id,
    method_name   = method_name,
    result_raw    = list(raw_bytes),
    result_text   = result_text,
    result_json   = list(result_json),
    logs          = list(res$logs %||% character()),
    block_height  = res$block_height %||% NA_integer_,
    block_hash    = res$block_hash %||% NA_character_,
    raw_response  = list(resp)
  )
}

