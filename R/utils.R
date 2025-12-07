#' Internal helper and endpoint management for nearjsonrpc
#'
#' near_set_endpoint sets the RPC endpoint used by package functions.
#' near_rpc is an internal requester used by exported functions to call the NEAR JSON-RPC.
#'
#' @param endpoint Character scalar. A full URL to a NEAR JSON-RPC endpoint, e.g. "https://rpc.testnet.near.org".
#' @return For near_set_endpoint: invisibly returns the endpoint (invisibly). For near_rpc: a parsed list response from the node.
#' @export
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' }
near_set_endpoint <- function(endpoint = "https://rpc.testnet.near.org") {
  stopifnot(is.character(endpoint), length(endpoint) == 1)
  options(nearjsonrpc.endpoint = endpoint)
  cli::cli_alert_info("NEAR RPC endpoint set to {endpoint}")
  invisible(endpoint)
}

# Provide a lightweight null-coalescing operator to keep code dependency-free in namespace
`%||%` <- function(x, y) {
  if (!is.null(x)) x else y
}

#' Internal: perform a json-rpc call to NEAR
#'
#' This is an internal helper and not exported. It uses httr2 to POST the request
#' body as JSON matching the NEAR RPC specs used by this package (a JSON object
#' with `method` and `params`). It returns a parsed list. HTTP errors raise via rlang::abort.
#'
#' @param method Character scalar with the RPC method name (e.g. "query").
#' @param params A list of parameters for the RPC method.
#' @param timeout Seconds to wait for response (numeric scalar). Defaults to 30.
#' @return A list parsed from JSON response. If the node returns an `error` field,
#'   an rlang::abort error is raised with the node message.
#' @keywords internal
near_rpc <- function(method, params = list(), timeout = 30) {
  stopifnot(is.character(method), length(method) == 1)
  if (!is.list(params)) rlang::abort("params must be a list")

  # Allow tests to inject a fake RPC implementation via options
  rpc_fn <- getOption("nearjsonrpc.rpc_fn")
  if (!is.null(rpc_fn) && is.function(rpc_fn)) {
    parsed <- rpc_fn(method = method, params = params, timeout = timeout)
    if (is.character(parsed)) parsed <- jsonlite::fromJSON(parsed, simplifyVector = FALSE)
    if (is.list(parsed) && !is.null(parsed$error)) {
      err <- parsed$error
      message <- if (!is.null(err$message)) err$message else jsonlite::toJSON(err)
      rlang::abort(paste0("NEAR RPC error: ", message))
    }
    return(parsed)
  }

  endpoint <- getOption("nearjsonrpc.endpoint", "https://rpc.testnet.near.org")
  if (!nzchar(endpoint)) rlang::abort("NEAR endpoint is not set. Use near_set_endpoint().")

  body <- list(method = method, params = params)

  req <- httr2::request(endpoint) %>%
    httr2::req_body_json(body) %>%
    httr2::req_headers(
      `User-Agent` = "nearjsonrpc R package",
      `Content-Type` = "application/json"
    ) %>%
    httr2::req_timeout(timeout)

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) rlang::abort(paste("HTTP request failed:", e$message))
  )

  # stop for HTTP status codes
  if (httr2::resp_status(resp) >= 400) {
    msg <- tryCatch(httr2::resp_body_string(resp), error = function(e) "")
    rlang::abort(paste0("NEAR RPC HTTP error ", httr2::resp_status(resp), ": ", msg))
  }

  text <- httr2::resp_body_string(resp)
  parsed <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) rlang::abort("Failed to parse JSON from RPC response: ", e$message)
  )

  if (is.list(parsed) && !is.null(parsed$error)) {
    # NEAR returns an `error` object in some cases
    err <- parsed$error
    message <- if (!is.null(err$message)) err$message else jsonlite::toJSON(err)
    rlang::abort(paste0("NEAR RPC error: ", message))
  }

  return(parsed)
}
