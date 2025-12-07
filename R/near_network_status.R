#' Retrieve NEAR network status
#'
#' Calls the `status` RPC method and returns a tibble with chain_id, sync_info, validators, and version.
#'
#' @return A tibble with chain_id, sync_info (list), validators (list), version (list)
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_network_status()
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/nodes#status}
#' @export
near_network_status <- function() {
  resp <- near_rpc("status", params = list())
  res <- if (!is.null(resp$result)) resp$result else resp
  if (!is.list(res)) rlang::abort("Unexpected response format from RPC")

  t <- tibble::tibble(
    chain_id = as.character(res$chain_id %||% NA_character_),
    sync_info = list(res$sync_info %||% list()),
    validators = list(res$validators %||% list()),
    version = list(res$version %||% list()),
    raw = list(res)
  )
  return(t)
}
