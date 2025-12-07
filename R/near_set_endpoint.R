#' Set or Retrieve the Active NEAR RPC Endpoint
#'
#' @description
#' Configures the JSON-RPC endpoint used by all `nearjsonrpc` functions.
#' Supports convenient shortcuts (`"mainnet"`, `"testnet"`, `"betanet"`) and any custom URL
#' (e.g., archival nodes, third-party providers like Pagoda, QuickNode, etc.).
#'
#' The current endpoint is stored in `options("nearjsonrpc.endpoint")` and defaults to **testnet**.
#'
#' @param endpoint Character scalar. One of:
#'   \itemize{
#'     \item `"mainnet"`, `"testnet"`, `"betanet"` — official public endpoints
#'     \item A full URL like `"https://archival-rpc.mainnet.near.org"` or `"https://rpc.quicknode.com/near/..."`
#'   }
#'   If omitted, returns the current endpoint without changing it.
#'
#' @return Invisibly returns the active endpoint (character). Useful for scripting.
#'
#' @export
#'
#' @examples
#' # Use shortcuts
#' near_set_endpoint("mainnet")
#' near_set_endpoint("testnet")     # default
#' near_set_endpoint("betanet")
#'
#'
#' # Custom or archival nodes
#' near_set_endpoint("https://archival-rpc.mainnet.near.org")
#' near_set_endpoint("https://rpc.mainnet.pagoda.co")
#'
#' # View current endpoint anytime
#' near_set_endpoint()              # returns current value
#' getOption("nearjsonrpc.endpoint)
#'
#' # Chain calls
#' near_set_endpoint("mainnet") |>
#'   near_query_account("near.near")
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc#using-rpc-endpoints}
#'
near_set_endpoint <- function(endpoint = NULL) {
  # Predefined official endpoints
  known_endpoints <- list(
    mainnet = "https://rpc.mainnet.near.org",
    testnet = "https://rpc.testnet.near.org",
    betanet = "https://rpc.betanet.near.org"
  )

  # If no argument → return current endpoint
  if (is.null(endpoint)) {
    current <- getOption("nearjsonrpc.endpoint", known_endpoints$testnet)
    cli::cli_alert_info("Current NEAR endpoint: {.url {current}}")
    return(invisible(current))
  }

  # Resolve shortcut names
  if (is.character(endpoint) && length(endpoint) == 1 && endpoint %in% names(known_endpoints)) {
    endpoint <- known_endpoints[[endpoint]]
  }

  # Validate input
  if (!is.character(endpoint) || length(endpoint) != 1 || !nzchar(endpoint)) {
    rlang::abort("`endpoint` must be a single non-empty string or one of: mainnet, testnet, betanet")
  }

  if (!grepl("^https?://", endpoint)) {
    rlang::abort("Invalid endpoint: must start with http:// or https:// — got {.val {endpoint}}")
  }

  # All good — store and report
  options(nearjsonrpc.endpoint = endpoint)
  cli::cli_alert_success("NEAR RPC endpoint set to {.url {endpoint}}")
  invisible(endpoint)
}
