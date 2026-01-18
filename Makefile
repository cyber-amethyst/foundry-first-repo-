# ============================
#  Load Environment Variables
# ============================
include .env
export $(shell sed 's/=.*//' .env)

# ============================
#  Variables
# ============================
SEPOLIA_ARGS = --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT_NAME)
VERIFY_ARGS  = --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

# ============================
#  Basic Tasks
# ============================
build:
	forge build

clean:
	forge clean

test:
	forge test -vv

# ============================
#  Deployment Tasks
# ============================
deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe \
		$(SEPOLIA_ARGS) \
		--broadcast \
		$(VERIFY_ARGS) \
		-vvvv
