library(testthat)

mock_resp <- list(result = list(transaction_hash = "txhash", status = list(success = TRUE), transaction = list(), receipts = list()))
withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_get_transaction_status returns tibble", {
  res <- near_get_transaction_status("txhash", "sender.testnet")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$tx_hash, "txhash")
})

test_that("near_get_transaction_status validates inputs", {
  expect_error(near_get_transaction_status(1, "a"))
  expect_error(near_get_transaction_status("a", 1))
})
