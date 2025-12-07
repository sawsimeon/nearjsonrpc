library(testthat)

# Simulate a call_function response where result is array of ints representing JSON string
json_text <- jsonlite::toJSON(list(value = 1), auto_unbox = TRUE)
raw_ints <- as.integer(charToRaw(json_text))
mock_resp <- list(result = list(result = raw_ints, logs = list("log1")))
withr::local_options(list(nearjsonrpc.rpc_fn = function(method, params, timeout) mock_resp))

test_that("near_call_view_function decodes result", {
  res <- near_call_view_function("contract.testnet", "method")
  expect_s3_class(res, "tbl_df")
  expect_true(!is.na(res$result_text))
  expect_true(is.list(res$result_json[[1]]))
})
