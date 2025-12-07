library(testthat)

mock_resp <- list(result = list(amount = "1000", locked = "0", code_hash = "1111", storage_usage = 42))

withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_query_account returns tibble with expected columns", {
  res <- near_query_account("example.testnet")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$account_id, "example.testnet")
  expect_equal(res$amount, "1000")
  expect_equal(res$storage_usage, 42)
})

test_that("near_query_account validates inputs", {
  expect_error(near_query_account(1))
  expect_error(near_query_account("a", finality = "final", block_id = 1))
})
