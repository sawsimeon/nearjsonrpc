#' Get Current Network Status and Node Info
#'
#'
#' @return A tibble with chain ID, sync status, validators, version, etc.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' near_network_status()
#' near_network_status()$validators[[1]]
#' }
#'
#' @seealso \url{https://docs.near.org/api/rpc/network#network-status}
#'
near_network_status <- function() {
  resp <- near_rpc("status", params = list())

  res <- resp$result %||% resp
  tibble::tibble(
    chain_id        = res$chain_id %||% NA_character_,
    latest_block_height = res$sync_info$latest_block_height %||% NA_integer_,
    latest_block_hash   = res$sync_info$latest_block_hash %||% NA_character_,
    syncing         = res$sync_info$syncing %||% NA,
    version         = res$version$version %||% NA_character_,
    protocol_version = res$protocol_version %||% NA_integer_,
    validators      = list(res$validators %||% list()),
    raw_response    = list(resp)
  )
}
