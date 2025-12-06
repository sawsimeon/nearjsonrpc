# nearjsonrpc <img src="man/figures/logo.png" align="right" width="140"/>

**An R client for the NEAR Protocol JSON-RPC API**  
[![CRAN status](https://www.r-pkg.org/badges/version/nearjsonrpc)](https://CRAN.R-project.org/package=nearjsonrpc)  
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

`nearjsonrpc` brings the full power of the NEAR Protocol JSON-RPC API directly into R — designed by an R developer, for R developers, data scientists, and blockchain analysts.

Built on the same philosophy as the popular `igfetchr` package (IG Trading API wrapper), `nearjsonrpc` provides clean, type-safe, well-documented functions that return tidy data frames (`tibbles`) by default, making it seamless to integrate NEAR blockchain data with `dplyr`, `ggplot2`, `shiny`, and the entire tidyverse.

## Features

- Full coverage of essential NEAR JSON-RPC methods
- Automatic JSON parsing into tidy tibbles
- Support for mainnet, testnet, and custom RPC endpoints
- Built-in retry logic and clear error messages
- Comprehensive documentation + vignettes
- 100% open-source and CRAN-ready

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

More methods coming soon!

## Installation

```r
# Install from CRAN (when available)
install.packages("nearjsonrpc")

# Or the development version from GitHub
# install.packages("remotes")
remotes::install_github("sawsimeon/nearjsonrpc")

```

## Usage

```r
library(nearjsonrpc)

# Set your preferred RPC endpoint (defaults to NEAR mainnet)
near_set_endpoint("https://rpc.mainnet.near.org")

# Or use testnet
near_set_endpoint("https://rpc.testnet.near.org")

# Get account balance and details
near_query_account("vitalik.near")
#> # A tibble: 1 × 8
#>   account_id     amount              staked storage_usage locked code_hash block_height block_hash
#>   <chr>          <chr>               <chr>          <int> <chr>  <chr>          <int> <chr>
#> 1 vitalik.near   1234567890000000... 0             1234  0      123abc...   112345678  abcdef123...

# Call a view function (e.g., get FT balance)
near_call_view_function(
  contract = "wrap.near",
  method   = "ft_balance_of",
  args     = list(account_id = "alice.near")
)

# Get latest block
near_get_block("final")
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
