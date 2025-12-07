library(testthat)

mock_resp_hash <- "txhash123"
mock_resp_full <- list(result = list(transaction_hash = "txhash123", status = list(success = TRUE), transaction = list(), receipts = list()))

withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) {
  if (params$wait_until == "NONE") mock_resp_hash else mock_resp_full
}))

test_that("near_broadcast_tx returns hash when NONE", {
  res <- near_broadcast_tx("B64TX", wait_until = "NONE")
  expect_equal(res$hash, "txhash123")
})

test_that("near_broadcast_tx returns detailed when waited", {
  res <- near_broadcast_tx("B64TX", wait_until = "FINAL")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$hash, "txhash123")
})
