# On-Chain Metadata: Cryptopunks

The main focus of this project was to understand how Cryptopunks stores data about each punk on-chain and how images are constructed from this data.

## Dependencies

- Foundry. Installation guide [here](https://book.getfoundry.sh/getting-started/installation).
- Python 3.

## Usage

- Requires a remote node provider RPC endpoint, such as Alchemy. To be set in the `.env` file (see [`.env.example`](./.env.example)).
- In the [test contract](/test/PunksData.t.sol), set the value of `PUNK_ID` to the punk index you want to construct layer by layer. To construct the images, run:

```
make images
```

- The images for each additional layer for `PUNK_ID` are saved to [`output.txt`](/analysis/output.txt).
- To visualize each layer side by side, run the provided Python script ([`visualize.py`](./analysis/visualize.py)):

  - Initialize virtual environment & install dependencies with:

  ```
  make init
  ```

  - Run the script:

  ```
  make run
  ```
