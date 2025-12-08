#' Get Current or Historical Epoch Validators with Real Stakes
#'
#' Fetches validator set for the current epoch (or a specific epoch) using the
#' official `validators` RPC method. This is the **only reliable public endpoint**
#' that returns actual stake amounts (in yoctoNEAR).
#'
#' @param epoch_id `NULL` (default) for current epoch, or a specific epoch hash/ID.
#'
#' @return A tibble with one row per validator:
#'   \item{account_id}{Validator account}
#'   \item{public_key}{Ed25519 public key}
#'   \item{stake_yocto}{Stake as big integer string}
#'   \item{stake_near}{Stake in whole NEAR (rounded to 2 decimals)}
#'   \item{is_slashed}{Logical: was validator slashed?}
#'   \item{shards}{Integer vector of assigned shards}
#'   \item{blocks_produced / blocks_expected}{Block production stats}
#'   \item{chunks_produced / chunks_expected}{Chunk production stats}
#'   \item{uptime_pct}{Overall uptime % (blocks + chunks)}
#'   \item{epoch_height}{Epoch height}
#'   \item{raw_response}{Full RPC result (for debugging)}
#'
#' @export
#'
#' @examples
#' # Current epoch validators
#' vals <- near_get_validators()
#' vals |> slice_head(n = 10)
#'
#' # Top 5 by stake
#' vals |> arrange(desc(stake_near)) |> slice_head(n = 5)
#'
#' # Find any slashed validators
#' vals |> filter(is_slashed)
#'
#' # Plot stake distribution
#' library(ggplot2)
#' vals |>
#'   slice_max(stake_near, n = 20) |>
#'   ggplot(aes(reorder(account_id, stake_near), stake_near, fill = is_slashed)) +
#'   geom_col() +
#'   coord_flip() +
#'   labs(title = "Top 20 NEAR Validators by Stake", x = "Validator", y = "Stake (NEAR)") +
#'   scale_fill_manual(values = c("FALSE" = "#00F6D2", "TRUE" = "#FF4444"))
#'
#' # Total staked NEAR
#' sum(vals$stake_near)
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/network#validators-current-epoch}
#'
near_get_validators <- function(epoch_id = NULL) {
  # Send correct params: [null] or ["epoch_hash"]
  params <- list(epoch_id)

  resp <- near_rpc("validators", params = params)
  res  <- resp$result %||% resp

  if (is.null(res) || length(res$current_validators) == 0) {
    cli::cli_alert_warning("No validators returned — check network or epoch_id")
    return(tibble::tibble())
  }

  current_validators <- res$current_validators

  tibble::tibble(
    account_id         = purrr::map_chr(current_validators, ~ .x$account_id %||% NA_character_),
    public_key         = purrr::map_chr(current_validators, ~ .x$public_key %||% NA_character_),
    stake_yocto        = purrr::map_chr(current_validators, ~ .x$stake %||% "0"),
    is_slashed         = purrr::map_lgl(current_validators, ~ .x$is_slashed %||% FALSE),
    shards             = purrr::map(current_validators, ~ .x$shards %||% integer()),
    blocks_produced    = purrr::map_int(current_validators, ~ .x$num_produced_blocks %||% 0L),
    blocks_expected    = purrr::map_int(current_validators, ~ .x$num_expected_blocks %||% 0L),
    chunks_produced    = purrr::map_int(current_validators, ~ .x$num_produced_chunks %||% 0L),
    chunks_expected    = purrr::map_int(current_validators, ~ .x$num_expected_chunks %||% 0L),
    epoch_height       = res$epoch_height %||% NA_integer_,
    raw_response       = list(resp)  # ← FIXED: added here, not in select()
  ) |>
    mutate(
      stake_near = round(as.numeric(stake_yocto) / 1e24, 2),
      uptime_pct = round(
        ((blocks_produced + chunks_produced) /
           (blocks_expected + chunks_expected + 1e-10)) * 100, 2  # avoid div/0
      )
    ) |>
    select(
      account_id, public_key, stake_yocto, stake_near, is_slashed,
      shards, blocks_produced, blocks_expected, chunks_produced, chunks_expected,
      uptime_pct, epoch_height, raw_response
    ) |>
    arrange(desc(stake_near))
}
