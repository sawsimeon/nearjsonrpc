#' Get Block Information by Height, Hash, or "final"
#'
#' Retrieves block header and chunk info. Works perfectly with `"final"`, numeric height, or block hash.
#'
#' @param block_id One of:
#'   \itemize{
#'     \item `"final"` — latest finalized block
#'     \item Integer — block height (e.g. 123456789)
#'     \item Character — full block hash
#'   }
#'
#' @return A tibble with block details including timestamp, author, gas price, etc.
#'
#' @export
#'
#' @examples
#' near_set_endpoint("mainnet")
#'
#' # Latest finalized block
#' near_get_block("final")
#'
#' # By height
#' near_get_block(176259877)
#'
#' # By hash (example)
#' near_get_block("CanDKa6nYDQ89iv5U7sE1YDFteBRkBG6qBJjiM5YwGtY")
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/block-chunk#get-block}
#'
near_get_block <- function(block_id = "final") {
  # Build correct JSON-RPC payload
  if (identical(block_id, "final")) {
    params <- list(finality = "final")
  } else if (is.numeric(block_id)) {
    params <- list(block_id = as.integer(block_id))
  } else if (is.character(block_id)) {
    params <- list(block_id = block_id)
  } else {
    rlang::abort("`block_id` must be character (hash), integer (height), or \"final\"")
  }

  payload <- list(
    jsonrpc = "2.0",
    id = "nearjsonrpc",
    method = "block",
    params = params
  )

  endpoint <- getOption("nearjsonrpc.endpoint", "https://rpc.mainnet.near.org")

  resp <- httr2::request(endpoint) %>%
    httr2::req_headers("Content-Type" = "application/json") %>%
    httr2::req_body_json(payload) %>%
    httr2::req_perform()

  out <- httr2::resp_body_json(resp)

  header <- out$result$header

  tibble::tibble(
    height          = header$height %||% NA_integer_,
    hash            = header$hash %||% NA_character_,
    prev_hash       = header$prev_hash %||% NA_character_,
    timestamp       = as.POSIXct(header$timestamp / 1e9, origin = "1970-01-01", tz = "UTC"),
    author          = out$result$author %||% NA_character_,
    chunks_included = header$chunks_included %||% NA_integer_,
    gas_price       = header$gas_price %||% NA_character_,
    total_supply    = header$total_supply %||% NA_character_,
    latest_protocol_version = header$latest_protocol_version %||% NA_integer_,
    raw_response    = list(out)
  )
}

