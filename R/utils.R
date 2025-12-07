#' Manage NEAR RPC Endpoint and Perform JSON-RPC Calls
#'
#' @description
#' These functions form the backbone of **nearjsonrpc**:
#' - `near_set_endpoint()` lets users switch between mainnet, testnet, or custom nodes.
#' - `near_rpc()` is the **internal** low-level JSON-RPC engine used by all exported functions.
#' - `%||%` is a lightweight null-coalescing operator (dependency-free).
#'
#' @name utils
#' @keywords internal
NULL

# Global option name (kept internal for consistency)
.NEAR_ENDPOINT_OPTION <- "nearjsonrpc.endpoint"

# Default public endpoints
.NEAR_ENDPOINTS <- list(
  mainnet = "https://rpc.mainnet.near.org",
  testnet = "https://rpc.testnet.near.org",
  betanet = "https://rpc.betanet.near.org"
)

#' Set or View the Active NEAR RPC Endpoint
#'
#' @description
#' Sets the JSON-RPC endpoint used by all functions in the package.
#' You can use the official public endpoints (`mainnet`, `testnet`) or any custom node.
#'
#' @param endpoint A character string with the full URL, or one of the shortcuts:
#'   `"mainnet"`, `"testnet"`, `"betanet"`.
#' @param .reset Logical. If `TRUE`, resets to the default (testnet). Mainly for testing.
#'
#' @return Invisibly returns the active endpoint.
#'
#' @export
#'
#' @examples
#' # Use testnet (default)
#' near_set_endpoint("testnet")
#'
#' # Switch to mainnet
#' near_set_endpoint("mainnet")
#'
#' # Custom archival node
#' near_set_endpoint("https://archival-rpc.mainnet.near.org")
#'
#' # View current endpoint
#' getOption("nearjsonrpc.endpoint")
#'
#' \dontrun{
#' # In a script or Shiny app
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_query_account("bowen.testnet")
#' }
near_set_endpoint <- function(endpoint = "testnet", .reset = FALSE) {
  if (.reset) {
    endpoint <- .NEAR_ENDPOINTS$testnet
  } else if (identical(endpoint, "mainnet")) {
    endpoint <- .NEAR_ENDPOINTS$mainnet
  } else if (identical(endpoint, "testnet")) {
    endpoint <- .NEAR_ENDPOINTS$testnet
  } else if (identical(endpoint, "betanet")) {
    endpoint <- .NEAR_ENDPOINTS$betanet
  }

  if (!is.character(endpoint) || length(endpoint) != 1 || !nzchar(endpoint)) {
    rlang::abort("`endpoint` must be a single non-empty character string or one of: mainnet, testnet, betanet")
  }

  # Basic URL validation
  if (!grepl("^https?://", endpoint)) {
    rlang::abort("Endpoint must start with http:// or https://")
  }

  options(.NEAR_ENDPOINT_OPTION := endpoint)
  cli::cli_alert_success("NEAR RPC endpoint → {.url {endpoint}}")
  invisible(endpoint)
}

#' Null-coalescing operator
#'
#' @param x,y Objects
#' @return `x` if not `NULL`, otherwise `y`
#' @keywords internal
`%||%` <- function(x, y) {
  if (!is.null(x)) x else y
}

#' Perform a Raw JSON-RPC Call to a NEAR Node
#'
#' @description
#' **Internal** function that powers every exported API call.
#' Sends a properly formatted JSON-RPC 2.0 request and handles errors gracefully.
#'
#' @param method Character scalar. The RPC method name (e.g., `"query"`, `"block"`, `"status"`).
#' @param params Named list of parameters (can be empty).
#' @param timeout Maximum seconds to wait for a response (default: 30).
#'
#' @return A parsed R object (usually a list) from the JSON response.
#'
#' @section Error handling:
#'   - HTTP errors → `rlang::abort()` with status code
#'   - JSON-RPC errors → informative message from the node
#'   - Network timeouts → clear error
#'
#' @keywords internal
near_rpc <- function(method,
                     params = list(),
                     timeout = getOption("nearjsonrpc.timeout", 30)) {

  # Input validation
  if (!is.character(method) || length(method) != 1 || !nzchar(method)) {
    rlang::abort("`method` must be a non-empty character scalar")
  }
  if (!is.list(params)) {
    rlang::abort("`params` must be a list")
  }
  if (!is.numeric(timeout) || timeout <= 0) {
    rlang::abort("`timeout` must be a positive number")
  }

  # Allow full test mocking via option (used by testthat + httptest2)
  mock_fn <- getOption("nearjsonrpc.mock_rpc")
  if (is.function(mock_fn)) {
    return(mock_fn(method = method, params = params, timeout = timeout))
  }

  endpoint <- getOption(.NEAR_ENDPOINT_OPTION, .NEAR_ENDPOINTS$testnet)

  body <- list(
    jsonrpc = "2.0",
    id      = "nearjsonrpc-r-package",
    method  = method,
    params  = params
  )

  req <- httr2::request(endpoint) %>%
    httr2::req_headers(
      `Content-Type`  = "application/json",
      `User-Agent`    = paste0("nearjsonrpc/", utils::packageVersion("nearjsonrpc"))
    ) %>%
    httr2::req_body_json(body) %>%
    httr2::req_timeout(timeout) %>%
    httr2::req_retry(max_tries = 3, backoff = ~ 2 * .x)

  resp <- req %>%
    httr2::req_perform() %>%
    httr2::resp_check_status()

  parsed <- resp %>%
    httr2::resp_body_json(simplifyVector = FALSE)

  # Handle JSON-RPC error field (NEAR nodes return {error: {...}})
  if (!is.null(parsed$error)) {
    err <- parsed$error
    msg <- err$message %||% jsonlite::toJSON(err, auto_unbox = TRUE)
    rlang::abort(c(
      "NEAR JSON-RPC error",
      x = msg,
      i = paste("Method:", method)
    ))
  }

  parsed$result
}
