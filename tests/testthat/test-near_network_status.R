library(testthat)

mock_resp <- list(result = list(chain_id = "testnet", sync_info = list(latest_block_hash = "h"), validators = list(), version = list()))
withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_network_status returns tibble", {
  res <- near_network_status()
  expect_s3_class(res, "tbl_df")
  expect_equal(res$chain_id, "testnet")
})
