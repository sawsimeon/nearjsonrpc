# nearjsonrpc <img src="man/figures/logo.png" align="right" width="140"/>

**An R client for the NEAR Protocol JSON-RPC API**  
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

`nearjsonrpc` brings the full power of the NEAR Protocol JSON-RPC API directly into R, designed by an R developer, for R developers, data scientists, and blockchain analysts.

`nearjsonrpc` provides clean, type-safe, well-documented functions that return tidy data frames (`tibbles`) by default, making it seamless to integrate NEAR blockchain data with `openssl`, `cyphr`, `sodium`, `digest`, `jsonlite`, `httr2`, `dplyr`, `tidyr`, `purrr`  and `shiny` R packages.

## Features

- Full coverage of essential NEAR JSON-RPC methods
- Automatic JSON parsing into tidy tibbles
- Support for mainnet, testnet, and custom RPC endpoints
- Built-in retry logic and clear error messages
- Comprehensive documentation + vignettes
- 100% open-source

### Currently implemented functions

| Function                        | Description                                      |
|----------------------------------|---------------------------------------------------|
| `near_query_account()`           | Get account details and balance                   |
| `near_get_block()`               | Fetch block by height or hash                     |
| `near_network_status()`          | Current network info and node status              |
| `near_broadcast_tx()`            | Broadcast signed transactions (sync & async)      |
| `near_get_transaction_status()` | Check status of a transaction                     |
| `near_call_view_function()`      | Call read-only contract functions                 |
| `near_get_access_keys()`         | List access keys for an account                   |
| `near_get_protocol_config()`     | Current protocol configuration and version        |
| `near_set_endpoint()`             | Set the Active NEAR RPC Endpoint                 |
| `near_get_validators()`           | Get Epoch Validators with Stake Amounts         |

More functions coming soon!

## Installation

```r
# Install from CRAN (when available)
# install.packages("nearjsonrpc")

# Or the development version from GitHub
# install.packages("remotes")
remotes::install_github("sawsimeon/nearjsonrpc")

```
## Warning First

DO NOT run real transactions on mainnet without fully understanding. Regarding the function `near_broadcast_tx()`, sending a real sign transaction
on mainnet will:

- Transfer real NEAR tokens
- Call real contracts
- Cost real gas
- Be permanent and irreversible

For testing `near_broadcast_tx()`, always use testnet first. 

## Get Testnet Near (Free Faucet)

To test functions that require transactions (like `near_broadcast_tx()`), you need test NEAR:

1. Create a testnet account at [wallet](https://wallet.testnet.near.org/) (e.g. `yourname.testnet`)
2. Fund it using the [faucet](https://near-faucet.io/).
3. You are ready to sign and broadcast transactions.

## Usage (Testnet)
```r
library(nearjsonrpc)

# Switch to testnet for safe testing
near_set_endpoint("testnet")
# ✔ NEAR RPC endpoint set to <https://rpc.testnet.near.org>
# Get account balance and details
near_query_account("sawsimeon.testnet")
#  A tibble: 1 × 8
#  account_id        amount       locked storage_usage code_hash block_height block_hash raw_response
#  <chr>             <chr>        <chr>          <int> <chr>            <int> <chr>      <list>      
# 1 sawsimeon.testnet 16999958035… 0                264 11111111…    227350669 pBMdeieJn… <named list>

```

### Get all access keys

```r 
near_get_access_keys("sawsimeon.testnet")
# A tibble: 2 × 5
#  public_key                                       access_key   block_height block_hash raw_response
#  <chr>                                            <list>              <int> <chr>      <list>      
# 1 ed25519:3UrY38puh6TfaEs4QTDLCvshckE5XGgsLNm6WBb… <named list>    227350765 4fLxH8wez… <named list>
# 2 ed25519:4soD2KJ9cTn8ajZSCmbn37KJvWq27H7XHxrJSz6… <named list>    227350765 4fLxH8wez… <named list>
```

### Get Network Status
```r
near_network_status()
# A tibble: 1 × 8
#  chain_id latest_block_height latest_block_hash         syncing version protocol_version validators
#  <chr>                  <int> <chr>                     <lgl>   <chr>              <int> <list>    
# 1 testnet            227350841 4du3GRMcCZJWVr4C5bZpZ7X3… FALSE   2.10.2                82 <list>    
#  1 more variable: raw_response <list>
```
### Get Validators Info

```r
near_get_validators()
# A tibble: 36 × 13
#   account_id    public_key stake_yocto stake_near is_slashed shards blocks_produced blocks_expected
#   <chr>         <chr>      <chr>            <dbl> <lgl>      <list>           <int>           <int>
# 1 node1         ed25519:B… 1060330659… 106033066. FALSE      <list>            6458            6458
# 2 node2         ed25519:7… 9133714949…  91337150. FALSE      <list>            5413            5413
# 3 kiln.pool.f8… ed25519:B… 8855238336…  88552383. FALSE      <list>            5276            5276
# 4 node3         ed25519:J… 8357287174…  83572872. FALSE      <list>            5132            5132
# 5 node0         ed25519:F… 7788726430…  77887264. FALSE      <list>            4616            4616
# 6 aurora.pool.… ed25519:9… 2163384481…  21633845. FALSE      <list>            1352            1352
# 7 01node.pool.… ed25519:3… 1844932878…  18449329. FALSE      <list>            1074            1074
# 8 stakely_v2.p… ed25519:7… 1288718663…  12887187. FALSE      <list>             798             798
# 9 legends.pool… ed25519:A… 1076379261…  10763793. FALSE      <list>             610             610
# 10 chorusone.po… ed25519:3… 5995233509…   5995234. FALSE      <list>             394             394
# ℹ 26 more rows
# ℹ 5 more variables: chunks_produced <int>, chunks_expected <int>, uptime_pct <dbl>,
#   epoch_height <int>, raw_response <list>
# ℹ Use `print(n = ...)` to see more rows
```

### Use near_broadcast_tx function
```r
tx_hash <- "6CzRJwPqcAufsTztarbtG3wbAzeV6XRGVQvmSDQWvdXo"
sender  <- "sawsimeon.testnet"
result <- near_get_transaction_status(tx_hash = tx_hash, sender_account_id = sender)
result
# A tibble: 1 × 5
#  hash                                       status       transaction  receipts_outcome raw_response
#  <chr>                                      <list>       <list>       <list>           <list>      
# 1 6CzRJwPqcAufsTztarbtG3wbAzeV6XRGVQvmSDQWv… <named list> <named list> <list [3]>       <named list>

```


## Usage (Mainnet)

```r
library(nearjsonrpc)
library(tidyr)
library(purrr)

# Use mainnet (or "testnet", "betanet")
near_set_endpoint("mainnet")
✔ NEAR RPC endpoint set to https://rpc.mainnet.near.org

# Get account balance and details
near_query_account("vitalik.near")
# # A tibble: 1 × 8
#   account_id   amount            locked storage_usage code_hash   block_height block_hash  raw_response
#   <chr>        <chr>             <chr>          <int> <chr>              <int> <chr>       <list>      
# 1 vitalik.near 5463293519585…    0           358058 55E7imni…      175996396 ECbLMFUSC… <named list>

# List all access keys
near_get_access_keys("vitalik.near")
# # A tibble: 7 × 5
#   public_key                                       access_key   block_height block_hash raw_response
#   <chr>                                            <list>              <int> <chr>      <list>      
# 1 ed25519:5a4CCWCJrnMGxSVtjMpxx3qUZ57qH9Tn1Ed8tKY… <named list>    175997459 9JDmQw9m3… <named list>
# 2 ed25519:6EBwyCYEjH1VsjJSUQo6jfH9yvowJ73bdzy9tAG… <named list>    175997459 9JDmQw9m3… <named list>
# 3 ed25519:77oj7oJGG3AoeRaKaAFoPdtZhxeDN3nDwAP3yC8… <named list>    175997459 9JDmQw9m3… <named list>
# 4 ed25519:7CH3JEY5abPhVcdPQxg8FmNnnHVF6E82tMzgFvo… <named list>    175997459 9JDmQw9m3… <named list>
# 5 ed25519:9ePBRZ3W1RpUKsaEripj55jiiREaoJG2Jn3UTBo… <named list>    175997459 9JDmQw9m3… <named list>
# 6 ed25519:Dr9NjCcEMvXEjECaJ9thavk8FQTnhLCgvC4vaft… <named list>    175997459 9JDmQw9m3… <named list>
# 7 ed25519:DyijRtwLRrSysLAgEAn5fdAfMdfYmSZez5HCLfh… <named list>    175997459 9JDmQw9m3… <named list>

# Network status + top validators
status <- near_network_status()

validators_vec <- map_chr(status$validators[[1]], "account_id")

validators_vec
#  [1] "figment.poolv1.near"                          "bisontrails2.poolv1.near" 
#  [3] "epochrunner.poolv1.near"                      "astro-stakers.poolv1.near"
#  [5] "zavodil.poolv1.near"                          "binancenode1.poolv1.near"
#  [7] "bitwise_1.poolv1.near"                        "sumerian.poolv1.near"
#  [9] "kiln-1.poolv1.near"                           "ledgerbyfigment.poolv1.near"
# [11] "sofarsonear.poolv1.near"                      "twinstake.poolv1.near"
# [13] "liver.pool.near"                              "p2p-org.poolv1.near"
# [15] "galaxydigital.poolv1.near"                    "epic.poolv1.near"
# [17] "nearvana.poolv1.near"                         "aca87218e28c41f5a693dee3dff12238.poolv1.near"
# [19] "foundry.poolv1.near"                          "nearone.pool.near"
# [21] "marcus.pool.near"                             "flipside.pool.near"
# [23] "stake1.poolv1.near"                           "macrodatarefinement.poolv1.near"
# [25] "dragonfly.poolv1.near"                        "d1.poolv1.near"
# [27] "rekt.poolv1.near"                             "here.poolv1.near"
# [29] "bisontrails.poolv1.near"                      "sweat_validator.poolv1.near"
# [31] "nansen.poolv1.near"                           "pandora.poolv1.near"
# [33] "republic.poolv1.near"                         "allnodes.poolv1.near"
# [35] "northernlights.poolv1.near"                   "x.poolv1.near"
# [37] "nearfans.poolv1.near"                         "stakin.poolv1.near"
# [39] "bodhiventures.poolv1.near"                    "everstake.poolv1.near"
# [41] "aurora.pool.near"                             "blockdaemon.poolv1.near"
# [43] "nodeasy.poolv1.near"                          "lux.poolv1.near"
# [45] "okx-earn.poolv1.near"                         "falcon.pool.near"
# [47] "kiln.poolv1.near"                             "chorusone.poolv1.near"
# [49] "buildlinks.poolv1.near"                       "erm.poolv1.near"
# [51] "bitcoinsuisse.poolv1.near"                    "anonymous.poolv1.near"
# [53] "baziliknear.poolv1.near"                      "npro.poolv1.near"
# [55] "luganodes.pool.near"                          "moonlet.poolv1.near"
# [57] "dsrvlabs.poolv1.near"                         "trust-nodes.poolv1.near"
# [59] "cryptium.poolv1.near"                         "openshards.poolv1.near"
# [61] "near-prime-public.poolv1.near"                "stakesabai.poolv1.near"
# [63] "meteor.poolv1.near"                           "lunanova.poolv1.near"
# [65] "staked.poolv1.near"                           "masternode24.poolv1.near"
# [67] "dexagon.poolv1.near"                          "stardust.poolv1.near"
# [69] "northstakenear.poolv1.near"                   "polkachu.poolv1.near"
# [71] "hb436_pool.poolv1.near"                       "qbit.poolv1.near"
# [73] "smart-stake.poolv1.near"                      "autostake.poolv1.near"
# [75] "pandateam.poolv1.near"                        "hapi.poolv1.near"
# [77] "stakely_io.poolv1.near"                       "gtnode-0.poolv1.near"
# [79] "brea.poolv1.near"                             "lavenderfive.poolv1.near"
# [81] "staking4all.poolv1.near"                      "fresh.poolv1.near"
# [83] "01node.poolv1.near"                           "colossus.poolv1.near"
# [85] "avado.poolv1.near"                            "pairpoint.poolv1.near"
# [87] "optimusvalidatornetwork.poolv1.near"          "sharpdarts.poolv1.near"
# [89] "readylayerone_staking.poolv1.near"            "deutschetelekom.poolv1.near"
# [91] "atomic-nodes.poolv1.near"                     "blackdragon.pool.near"
# [93] "namdokmai.poolv1.near"                        "cryptogarik.poolv1.near"
# [95] "near-prime.poolv1.near"                       "gfi-validator.poolv1.near"
# [97] "lionstake.poolv1.near"                        "hashquark.poolv1.near"
# [99] "pangdao.poolv1.near"                          "oe.poolv1.near"


```

## Use Cases

- NEAR blockchain analytics
- Building NEAR-based applications
- Automated monitoring of NEAR network status
- Smart contract development and testing

## Documentation & Examples

For full documentation and examples, see the [package vignettes](https://sawsimeon.github.io/nearjsonrpc/). Whether it's new RPC methods, bug fixes, documentation, or example dashboards.



## Contributing

Contributions are welcome! Please open issues or pull requests for any improvements or bug fixes.

## License

MIT License: <https://opensource.org/license/MIT>


## Contact

For questions or feedback, please contact [Saw Simeon](mailto:sawsimeon@hotmail.com).
