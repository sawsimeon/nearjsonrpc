#' Set or Retrieve the Active NEAR RPC Endpoint
#'
#' @description
#' Configures the JSON-RPC endpoint used by **all** `nearjsonrpc` functions.
#'
#' Supports:
#' - Shortcuts: `"mainnet"`, `"testnet"`, `"betanet"`
#' - Any custom URL (archival nodes, Pagoda, QuickNode, Lava, etc.)
#' - No argument → prints and returns current endpoint
#'
#' The endpoint is stored in `options("nearjsonrpc.endpoint")` and defaults to **testnet**.
#'
#' @param endpoint Character scalar. Use:
#'   \itemize{
#'     \item `"mainnet"` → `https://rpc.mainnet.near.org`
#'     \item `"testnet"` → `https://rpc.testnet.near.org` (default)
#'     \item `"betanet"` → `https://rpc.betanet.near.org`
#'     \item Any full URL like `"https://archival-rpc.mainnet.near.org"`
#'   }
#'   If `NULL` (or omitted), returns the current endpoint.
#'
#' @return Invisibly returns the active endpoint. Useful for piping.
#'
#' @export
#'
#' @examples
#' # 1. Use shortcuts
#' near_set_endpoint("mainnet")
#' near_set_endpoint("testnet")     # default
#' near_set_endpoint("betanet")
#'
#' # 2. Custom / archival / third-party nodes
#' near_set_endpoint("https://archival-rpc.mainnet.near.org")
#' near_set_endpoint("https://rpc.mainnet.pagoda.co")
#' near_set_endpoint("https://near.lava.build")  # Lava Network
#'
#' # 3. Just view current endpoint (no change)
#' near_set_endpoint()
#' getOption("nearjsonrpc.endpoint")
#'
#' # 4. Chain with other functions
#' near_set_endpoint("mainnet") |>
#'   near_query_account("near.near")
#'
#' # 5. Use in scripts with error handling
#' tryCatch({
#'   near_set_endpoint("invalid-url")
#' }, error = function(e) message("Bad URL! ", e$message))
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc#using-rpc-endpoints}
#' \url{https://near.org/ecosystem/rpc-providers}
#'
near_set_endpoint <- function(endpoint = NULL) {
  # Official public endpoints
  known_endpoints <- list(
    mainnet = "https://rpc.mainnet.near.org",
    testnet = "https://rpc.testnet.near.org",
    betanet = "https://rpc.betanet.near.org"
  )

  # No argument → show current endpoint
  if (is.null(endpoint)) {
    current <- getOption("nearjsonrpc.endpoint", known_endpoints$testnet)
    cli::cli_alert_info("Current NEAR endpoint: {.url {current}}")
    return(invisible(current))
  }

  # Resolve shortcuts
  if (is.character(endpoint) && length(endpoint) == 1 && endpoint %in% names(known_endpoints)) {
    endpoint <- known_endpoints[[endpoint]]
  }

  # Validate
  if (!is.character(endpoint) || length(endpoint) != 1 || !nzchar(endpoint)) {
    rlang::abort("`endpoint` must be a single non-empty string")
  }

  if (!grepl("^https?://", endpoint)) {
    rlang::abort("Invalid endpoint — must start with http:// or https://\n  You provided: {.val {endpoint}}")
  }

  # Store and report
  options("nearjsonrpc.endpoint" = endpoint)  # ← THIS WAS THE BUG! No :=
  cli::cli_alert_success("NEAR RPC endpoint set to {.url {endpoint}}")

  invisible(endpoint)
}
