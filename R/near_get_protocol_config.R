#' Retrieve Current or Historical NEAR Protocol Configuration
#'
#' Queries the **experimental** `EXPERIMENTAL_protocol_config` RPC method to get the full protocol configuration
#' at a given block — including gas costs, fees, runtime limits, staking parameters, and more.
#' Extremely useful for analytics, tooling, or understanding protocol upgrades over time.
#'
#' @param finality Character. Block finality: `"final"` (default & safest) or `"optimistic"` (faster).
#' @param block_id Integer or character. Optional specific block height or hash. Use this for historical queries.
#'   Cannot be used together with `finality`.
#'
#' @return A tibble with one row containing:
#'   \item{block_height}{Height at which config was fetched}
#'   \item{block_hash}{Hash of the block}
#'   \item{config}{Full protocol config as a named list (deeply nested)}
#'   \item{runtime_config}{Runtime-specific settings (storage costs, WASM limits, etc.)}
#'   \item{raw_response}{Complete RPC response for debugging}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Current (latest final) protocol config
#' cfg <- near_get_protocol_config()
#' cfg
#'
#' # Extract storage cost per byte
#' cfg$runtime_config$storage_amount_per_byte
#'
#' # Compare gas prices across time
#' old <- near_get_protocol_config(block_id = 60000000)
#' new <- near_get_protocol_config(block_id = 120000000)
#'
#' list(
#'   old_gas_price = old$config$min_gas_price,
#'   new_gas_price = new$config$min_gas_price
#' )
#'
#' # How much does it cost to store 1 KB today?
#' cost_yocto <- 1e3 * cfg$runtime_config$storage_config$storage_amount_per_byte
#' cost_near  <- cost_yocto / 1e24
#' cat("Cost to store 1 KB:", cost_near, "NEAR")
#'
#' # View all fee schedules
#' cfg$config$fees
#' }
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/protocol#protocol-config}
#' \url{https://near.org/blog/near-protocol-economics}
#'
near_get_protocol_config <- function(
    finality = c("final", "optimistic"),
    block_id = NULL
) {
  # Input validation
  if (!is.null(block_id) && !missing(finality)) {
    rlang::abort("Use either `finality` OR `block_id`, not both")
  }

  finality <- match.arg(finality)

  # Build params — exactly one of finality or block_id
  params <- list()
  if (!is.null(block_id)) {
    params$block_id <- block_id
  } else {
    params$finality <- finality
  }

  # Call the experimental endpoint
  resp <- near_rpc("EXPERIMENTAL_protocol_config", params = params)

  # Extract result
  res <- resp$result %||% resp
  if (is.null(res)) {
    rlang::abort("Empty response from EXPERIMENTAL_protocol_config — check endpoint or block ID")
  }

  # Extract runtime config for easy access
  runtime_cfg <- res$runtime_config %||% list()

  tibble::tibble(
    block_height    = res$block_height %||% NA_integer_,
    block_hash      = res$block_hash %||% NA_character_,
    config          = list(res),
    runtime_config  = list(runtime_cfg),
    raw_response    = list(resp)
  )
}
