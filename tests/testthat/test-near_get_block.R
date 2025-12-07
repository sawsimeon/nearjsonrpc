library(testthat)

mock_resp <- list(result = list(header = list(hash = "abc", height = 100), chunks = list(list(chunk_hash = "c1"))))
withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_get_block returns tibble with header and chunks", {
  res <- near_get_block()
  expect_s3_class(res, "tbl_df")
  expect_true(is.list(res$header[[1]]))
  expect_equal(res$header[[1]]$hash, "abc")
})

test_that("near_get_block input validation", {
  expect_error(near_get_block(finality = "final", block_id = 10))
})
