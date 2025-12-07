#' Get NEAR protocol config (experimental)
#'
#' Calls `EXPERIMENTAL_protocol_config` to fetch protocol configuration.
#'
#' @param finality Character scalar. One of "final" or "optimistic". Defaults to "final".
#' @param block_id Character or integer. Optional block id.
#' @param epoch_id Character scalar. Optional epoch id.
#' @return A tibble with config in a list-column `config` and raw.
#' @examples
#' \dontrun{
#' near_set_endpoint("https://rpc.testnet.near.org")
#' near_get_protocol_config(finality = "final")
#' near_get_protocol_config(epoch_id = "abcd1234")
#' }
#' @seealso
#'  URL{https://docs.near.org/api/rpc/experimental}
#' @export
near_get_protocol_config <- function(finality = "final", block_id = NULL, epoch_id = NULL) {
  # only one of finality/block_id/epoch_id
  specifiers <- sum(!is.null(finality), !is.null(block_id), !is.null(epoch_id))
  if (specifiers > 1) rlang::abort("Specify only one of finality, block_id, or epoch_id")

  params <- list()
  if (!is.null(block_id)) params$block_id <- block_id else if (!is.null(epoch_id)) params$epoch_id <- epoch_id else params$finality <- finality

  resp <- near_rpc("EXPERIMENTAL_protocol_config", params = params)
  res <- if (!is.null(resp$result)) resp$result else resp
  if (!is.list(res)) rlang::abort("Unexpected response format from RPC")

  t <- tibble::tibble(config = list(res), raw = list(res))
  return(t)
}
