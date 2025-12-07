#' Call a view function on a smart contract
#'
#' Uses `query` with `request_type = "call_function"`. Arguments are encoded as base64 of JSON.
#'
#' @param account_id Character scalar. Contract account id.
#' @param method_name Character scalar. Method to call.
#' @param args A list of arguments (will be JSON-encoded then base64-ed). Defaults to empty list.
#' @param finality Character scalar. One of "final" or "optimistic". Defaults to "final".
#' @param block_id Character or integer. Optional block id.
#' @return A tibble with result_raw (raw byte vector as base64), result_text (decoded string), result_json (parsed JSON if possible), logs, and raw.
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_call_view_function("counter.testnet", "get_num")
#' near_call_view_function("example.testnet", "view_method", args = list(key = "value"))
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/contracts}
#' @export
near_call_view_function <- function(account_id, method_name, args = list(), finality = "final", block_id = NULL) {
  if (missing(account_id) || !is.character(account_id) || length(account_id) != 1) rlang::abort("account_id must be a single string")
  if (missing(method_name) || !is.character(method_name) || length(method_name) != 1) rlang::abort("method_name must be a single string")
  if (!is.list(args)) rlang::abort("args must be a list")
  if (!is.null(block_id) && !missing(finality)) rlang::abort("Specify either finality or block_id, not both")

  args_json <- jsonlite::toJSON(args, auto_unbox = TRUE)
  args_b64 <- jsonlite::base64_enc(charToRaw(args_json))

  params <- list(request_type = "call_function", account_id = account_id, method_name = method_name, args_base64 = args_b64)
  if (!is.null(block_id)) params$block_id <- block_id else params$finality <- finality

  resp <- near_rpc("query", params = params)
  res <- if (!is.null(resp$result)) resp$result else resp

  if (!is.list(res)) rlang::abort("Unexpected response format from RPC")

  # res$result is typically a list of integers (bytes)
  raw_bytes <- NULL
  if (!is.null(res$result)) {
    # If it's a vector of ints
    if (is.numeric(res$result)) {
      raw_bytes <- as.raw(as.integer(res$result))
    } else if (is.character(res$result)) {
      # sometimes returned as base64 string
      raw_bytes <- jsonlite::base64_dec(res$result)
    }
  }

  result_text <- tryCatch(rawToChar(raw_bytes), error = function(e) NA_character_)
  result_json <- tryCatch(jsonlite::fromJSON(result_text, simplifyVector = FALSE), error = function(e) NULL)

  t <- tibble::tibble(
    account_id = account_id,
    method_name = method_name,
    result_raw = list(raw_bytes),
    result_text = result_text,
    result_json = list(result_json),
    logs = list(res$logs %||% list()),
    raw = list(res)
  )
  return(t)
}
