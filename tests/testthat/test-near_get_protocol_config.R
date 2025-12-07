library(testthat)

mock_resp <- list(result = list(protocol_version = 1, config = list()))
withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_get_protocol_config returns config tibble", {
  res <- near_get_protocol_config(finality = "final")
  expect_s3_class(res, "tbl_df")
  expect_true(is.list(res$config[[1]]))
})
