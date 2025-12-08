#' Get Block Information by Height or Hash
#'
#' @param block_id Block height (integer), hash (character), or `"final"` (latest finalized).
#' @return A tibble with block header and chunk information.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' near_get_block("final")
#' near_get_block(123456789)
#' near_get_block("8Yd8...abc")
#' }
#'
#' @seealso \url{https://docs.near.org/api/rpc/blocks}
#'
near_get_block <- function(block_id = "final") {
  params <- list(block_id = block_id)
  resp <- near_rpc("block", params)

  res <- resp$result %||% resp
  tibble::tibble(
    height        = res$header$height %||% NA_integer_,
    hash          = res$header$hash %||% NA_character_,
    prev_hash     = res$header$prev_hash %||% NA_character_,
    timestamp     = as.POSIXct(res$header$timestamp / 1e9, origin = "1970-01-01"),
    author        = res$author %||% NA_character_,
    chunks_count  = length(res$chunks),
    gas_price     = res$header$gas_price %||% NA_character_,
    raw_response  = list(resp)
  )
}
