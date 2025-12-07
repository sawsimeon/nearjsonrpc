library(testthat)

mock_resp <- list(result = list(keys = list(list(public_key = "ed25519:abc", access_key = list(permission = "FullAccess")))))
withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_get_access_keys returns keys tibble", {
  res <- near_get_access_keys("example.testnet")
  expect_s3_class(res, "tbl_df")
  expect_equal(res$public_key[1], "ed25519:abc")
  expect_true(is.list(res$access_key[[1]]))
})
