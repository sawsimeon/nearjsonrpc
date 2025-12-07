#' Get Current Protocol Configuration
#'
#' @param finality `"final"` (default) or `"optimistic"`.
#' @param block_id Optional block specifier.
#'
#' @return Protocol parameters (fees, gas, runtime config, etc.).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' near_get_protocol_config()
#' near_get_protocol_config(block_id = 100000000)
#' }
#'
#' @seealso \url{https://docs.near.org/api/rpc/protocol#protocol-config}
#'
near_get_protocol_config <- function(finality = "final", block_id = NULL) {
  {
    params <- list()
    if (!is.null(block_id)) params$block_id <- block_id else params$finality <- finality

    resp <- near_rpc("EXPERIMENTAL_protocol_config", params)
    tibble::tibble(raw_config = list(resp$result %||% resp))
  }
