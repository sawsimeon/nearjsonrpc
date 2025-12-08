#' Get Current Epoch Validators with Real Stake Amounts
#'
#' Uses the dedicated `validators` RPC method (null block_id = current epoch).
#' This is the **only** reliable way to get actual stake values from public RPCs.
#'
#' @return A tibble with account_id, stake (yoctoNEAR), stake_near (whole NEAR), uptime, etc.
#'
#' @export
#'
#' @examples
#' # Top 10 validators by stake
#' near_get_validators() |>
#'   slice_head(n = 10)
#'
#' # Plot stake distribution
#' library(ggplot2)
#' near_get_validators() |>
#'   ggplot(aes(reorder(account_id, stake_near), stake_near)) +
#'   geom_col(fill = "#00F6D2") +
#'   coord_flip() +
#'   labs(title = "Top NEAR Validators by Stake", x = "Validator", y = "Stake (NEAR)")
#'
#' @seealso
#' \url{https://docs.near.org/api/rpc/network#validators-current-epoch}
#'
near_get_validators <- function() {
  # null block_id = current epoch
  resp <- near_rpc("validators", params = list(block_id = NULL))
  res <- resp$result %||% resp

  current_validators <- res$current_validators %||% list()

  if (length(current_validators) == 0) {
    return(tibble::tibble(
      account_id = character(),
      stake_yocto = character(),
      stake_near = numeric(),
      is_slashed = logical(),
      blocks_produced = integer(),
      blocks_expected = integer(),
      uptime_pct = numeric()
    ))
  }

  tibble::tibble(
    account_id       = purrr::map_chr(current_validators, ~ .x$account_id %||% NA_character_),
    stake_yocto      = purrr::map_chr(current_validators, ~ .x$stake %||% "0"),
    is_slashed       = purrr::map_lgl(current_validators, ~ .x$is_slashed %||% FALSE),
    blocks_produced  = purrr::map_int(current_validators, ~ .x$num_produced_blocks %||% 0L),
    blocks_expected  = purrr::map_int(current_validators, ~ .x$num_expected_blocks %||% 0L)
  ) |>
    mutate(
      stake_near = round(as.numeric(stake_yocto) / 1e24, 2),
      uptime_pct = round((blocks_produced / blocks_expected) * 100, 2)
    ) |>
    select(account_id, stake_yocto, stake_near, is_slashed, blocks_produced, blocks_expected, uptime_pct) |>
    arrange(desc(stake_near))
}
