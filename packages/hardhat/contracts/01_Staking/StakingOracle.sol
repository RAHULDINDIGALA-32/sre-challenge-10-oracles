// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { ORA } from "./OracleToken.sol";
import { StatisticsUtils } from "../utils/StatisticsUtils.sol";

contract StakingOracle {
    using StatisticsUtils for uint256[];

    /////////////////
    /// Errors //////
    /////////////////

    error NodeNotRegistered();
    error InsufficientStake();
    error NodeAlreadyRegistered();
    error NoRewardsAvailable();
    error OnlyPastBucketsAllowed();
    error NodeAlreadySlashed();
    error AlreadyReportedInCurrentBucket();
    error NotDeviated();
    error WaitingPeriodNotOver();
    error InvalidPrice();
    error IndexOutOfBounds();
    error NodeNotAtGivenIndex();
    error TransferFailed();
    error MedianNotRecorded();
    error BucketMedianAlreadyRecorded();
    error NodeDidNotReport();

    //////////////////////
    /// State Variables //
    //////////////////////

    ORA public oracleToken;

    struct OracleNode {
        uint256 stakedAmount;
        uint256 lastReportedBucket;
        uint256 reportCount;
        uint256 claimedReportCount;
        uint256 firstBucket; // block when node registered
        bool active;
    }

    struct BlockBucket {
        mapping(address => bool) slashedOffenses;
        address[] reporters;
        uint256[] prices;
        uint256 medianPrice;
    }


    mapping(address => OracleNode) public nodes;
    mapping(uint256 => BlockBucket) public blockBuckets; // one bucket per 24 blocks
    address[] public nodeAddresses;

    uint256 public constant MINIMUM_STAKE = 100 ether;
    uint256 public constant BUCKET_WINDOW = 24; // 24 blocks
    uint256 public constant SLASHER_REWARD_PERCENTAGE = 10;
    uint256 public constant REWARD_PER_REPORT = 1 ether; // ORA Token reward per report
    uint256 public constant INACTIVITY_PENALTY = 1 ether;
    uint256 public constant MISREPORT_PENALTY = 100 ether;
    uint256 public constant MAX_DEVIATION_BPS = 1000; // 10% default threshold
    uint256 public constant WAITING_PERIOD = 2; // 2 buckets after last report before exit allowed

    ////////////////
    /// Events /////
    ////////////////

    event NodeRegistered(address indexed node, uint256 stakedAmount);
    event PriceReported(address indexed node, uint256 price, uint256 bucketNumber);
    event BucketMedianRecorded(uint256 indexed bucketNumber, uint256 medianPrice);
    event NodeSlashed(address indexed node, uint256 amount);
    event NodeRewarded(address indexed node, uint256 amount);
    event StakeAdded(address indexed node, uint256 amount);
    event NodeExited(address indexed node, uint256 amount);

    ///////////////////
    /// Modifiers /////
    ///////////////////

    /**
     * @notice Modifier to restrict function access to registered oracle nodes
     * @dev Checks if the sender has a registered node in the mapping
     */
    modifier onlyNode() {
        if (nodes[msg.sender].active == false) revert NodeNotRegistered();
        _;
    }

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address oraTokenAddress) {
        oracleToken = ORA(payable(oraTokenAddress));
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    /**
     * @notice Registers a new oracle node with initial ORA token stake
     * @dev Creates a new OracleNode struct and adds the sender to the nodeAddresses array.
     *      Requires minimum stake amount and prevents duplicate registrations.
     */
    function registerNode(uint256 amount) public {
        if (nodes[msg.sender].active) revert NodeAlreadyRegistered();
        if (amount < MINIMUM_STAKE) revert InsufficientStake();
        // Transfer ORA tokens from the node to the contract as stake
        bool success = oracleToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
        // Create the node and add to the mapping and addresses array
        nodes[msg.sender] = OracleNode({
            stakedAmount: amount,
            lastReportedBucket: 0,
            reportCount: 0,
            claimedReportCount: 0,
            firstBucket: getCurrentBucketNumber(),
            active: true
        });

        nodeAddresses.push(msg.sender);
        emit NodeRegistered(msg.sender, amount);
    }

    /**
     * @notice Updates the price reported by an oracle node (only registered nodes)
     * @dev Updates the node's lastReportedBucket and price in that bucket. Requires sufficient stake.
     * @param price The new price value to report
     */
    function reportPrice(uint256 price) public onlyNode {
        if (price == 0) revert InvalidPrice();
        if (getEffectiveStake(msg.sender) < MINIMUM_STAKE) revert InsufficientStake();
        uint256 currentBucket = getCurrentBucketNumber();
        OracleNode storage node = nodes[msg.sender];
        if (node.lastReportedBucket == currentBucket) revert AlreadyReportedInCurrentBucket();
        
        BlockBucket storage bucket = blockBuckets[currentBucket];
        bucket.reporters.push(msg.sender);
        bucket.prices.push(price);

        node.lastReportedBucket = currentBucket;
        node.reportCount += 1;

        emit PriceReported(msg.sender, price, currentBucket);
    }

    /**
     * @notice Allows active and inactive nodes to claim accumulated ORA token rewards
     * @dev Calculates rewards based on time elapsed since last claim.
     */
    function claimReward() public {
        OracleNode storage node = nodes[msg.sender];

        uint256 delta = node.reportCount - node.claimedReportCount;
        if (delta == 0) revert NoRewardsAvailable();

        node.claimedReportCount = node.reportCount;
        uint256 reward = delta * REWARD_PER_REPORT;
        // bool success = oracleToken.transfer(msg.sender, reward);
        // if(!success) revert TransferFailed();
        oracleToken.mint(msg.sender, reward);

        emit NodeRewarded(msg.sender, reward);

    }

    /**
     * @notice Allows a registered node to increase its ORA token stake
     */
    function addStake(uint256 amount) public onlyNode {
         if (amount == 0) revert InsufficientStake();

         bool success = oracleToken.transferFrom(msg.sender, address(this), amount);
         if (!success) revert TransferFailed();

         nodes[msg.sender].stakedAmount += amount;
         emit StakeAdded(msg.sender, amount);
    }

    /**
     * @notice Records the median price for a bucket once sufficient reports are available
     * @dev Anyone who uses the oracle's price feed can call this function to record the median price for a bucket.
     * @param bucketNumber The bucket number to finalize
     */
    function recordBucketMedian(uint256 bucketNumber) public {
        if (bucketNumber >= getCurrentBucketNumber()) revert OnlyPastBucketsAllowed();
        BlockBucket storage bucket = blockBuckets[bucketNumber];
        if(bucket.medianPrice !=0) revert BucketMedianAlreadyRecorded(); // prevent overwriting median once recorded 
        if(bucket.prices.length == 0) revert NodeDidNotReport();

        uint256[] memory prices = bucket.prices;
        prices.sort();
        bucket.medianPrice = prices.getMedian();

        emit BucketMedianRecorded(bucketNumber, bucket.medianPrice); 
    }

    /**
     * @notice Slashes a node for giving a price that is deviated too far from the average
     * @param nodeToSlash The address of the node to slash
     * @param bucketNumber The bucket number to slash the node from
     * @param reportIndex The index of node in the prices and reporters arrays
     * @param nodeAddressesIndex The index of the node to slash in the nodeAddresses array
     */
    function slashNode(
        address nodeToSlash,
        uint256 bucketNumber,
        uint256 reportIndex,
        uint256 nodeAddressesIndex
    ) public {
        if (!nodes[nodeToSlash].active) revert NodeNotRegistered();
        if (bucketNumber >= getCurrentBucketNumber()) revert OnlyPastBucketsAllowed();
        
        BlockBucket storage bucket = blockBuckets[bucketNumber];
        if (bucket.medianPrice == 0) revert MedianNotRecorded();
        if (bucket.slashedOffenses[nodeToSlash]) revert NodeAlreadySlashed();
        if (reportIndex >= bucket.reporters.length) revert IndexOutOfBounds();
        if (nodeToSlash != bucket.reporters[reportIndex]) revert NodeNotAtGivenIndex();

        uint256 reportedPrice = bucket.prices[reportIndex];
        if (reportedPrice == 0) revert NodeDidNotReport();
        if (!_checkPriceDeviated(reportedPrice, bucket.medianPrice)) revert NotDeviated();

        bucket.slashedOffenses[nodeToSlash] = true;
        OracleNode storage node = nodes[nodeToSlash];

        uint256 penaltyAmount = MISREPORT_PENALTY > node.stakedAmount ? node.stakedAmount : MISREPORT_PENALTY;
        node.stakedAmount -= penaltyAmount;

        if (node.stakedAmount == 0) {
            _removeNode(nodeToSlash, nodeAddressesIndex);
            emit NodeExited(nodeToSlash, 0);
        }

        uint256 rewardAmount = (penaltyAmount * SLASHER_REWARD_PERCENTAGE) / 100;

        bool success = oracleToken.transfer(msg.sender, rewardAmount);
        if (!success) revert TransferFailed();

        emit NodeSlashed(nodeToSlash, penaltyAmount);

    }

    /**
     * @notice Allows a registered node to exit the system and withdraw their stake
     * @dev Removes the node from the system and sends the stake to the node.
     *      Requires that the the initial waiting period has passed to ensure the
     *      node has been slashed if it reported a bad price before allowing it to exit.
     * @param index The index of the node to remove in nodeAddresses
     */
    function exitNode(uint256 index) public onlyNode {
        if (index >= nodeAddresses.length) revert IndexOutOfBounds();
        if (nodeAddresses[index] != msg.sender) revert NodeNotAtGivenIndex();
        
        OracleNode storage node = nodes[msg.sender];
       if (getCurrentBucketNumber() < node.lastReportedBucket + WAITING_PERIOD) revert WaitingPeriodNotOver();

        uint256 effectiveStake = getEffectiveStake(msg.sender);

        _removeNode(nodeAddresses[index], index);
        nodes[msg.sender].stakedAmount = 0; // set stake to 0 after removing node to prevent re-entrancy issues

        bool success = oracleToken.transfer(msg.sender, effectiveStake);
        if (!success) revert TransferFailed();

        emit NodeExited(msg.sender, effectiveStake);
    }

    ////////////////////////
    /// View Functions /////
    ////////////////////////

    /**
     * @notice Returns the current bucket number
     * @dev Returns the current bucket number based on the block number
     * @return The current bucket number
     */
    function getCurrentBucketNumber() public view returns (uint256) {
        return (block.number / BUCKET_WINDOW) + 1;
    }

    /**
     * @notice Returns the list of registered oracle node addresses
     * @return Array of registered oracle node addresses
     */
    function getNodeAddresses() public view returns (address[] memory) {
        return nodeAddresses;
    }

    /**
     * @notice Returns the stored median price from the most recently completed bucket
     * @dev Requires that the median for the bucket be recorded via recordBucketMedian
     * @return The median price for the last finalized bucket
     */
    function getLatestPrice() public view returns (uint256) {
        uint256 latestBucket = getCurrentBucketNumber() - 1;
        if (blockBuckets[latestBucket].medianPrice == 0) revert MedianNotRecorded();
        
        return blockBuckets[latestBucket].medianPrice;
    }

    /**
     * @notice Returns the stored median price from a specified bucket
     * @param bucketNumber The bucket number to read the median price from
     * @return The median price stored for the bucket
     */
    function getPastPrice(uint256 bucketNumber) public view returns (uint256) {
       // if (bucketNumber >= getCurrentBucketNumber()) revert OnlyPastBucketsAllowed();
        if (blockBuckets[bucketNumber].medianPrice == 0) revert MedianNotRecorded();
        
        return blockBuckets[bucketNumber].medianPrice;
    }

    /**
     * @notice Returns the price and slashed status of a node at a given bucket
     * @param nodeAddress The address of the node to get the data for
     * @param bucketNumber The bucket number to get the data from
     * @return price The price of the node at the specified bucket
     * @return slashed The slashed status of the node at the specified bucket
     */
    function getSlashedStatus(
        address nodeAddress,
        uint256 bucketNumber
    ) public view returns (uint256 price, bool slashed) {
        BlockBucket storage bucket = blockBuckets[bucketNumber];
        for (uint256 i = 0; i < bucket.reporters.length; i++) {
            if (bucket.reporters[i] == nodeAddress) {
                price = bucket.prices[i];
                slashed = bucket.slashedOffenses[nodeAddress];
                return (price, slashed);
            }
        }
       // revert NodeNotRegistered(); // node did not report in this bucket, so consider it not registered for this bucket
    }

    /**
     * @notice Returns the effective stake accounting for inactivity penalties via missed buckets
     * @dev Effective stake = stakedAmount - (missedBuckets * INACTIVITY_PENALTY), floored at 0
     */
    function getEffectiveStake(address nodeAddress) public view returns (uint256) {
        OracleNode memory node = nodes[nodeAddress];
        if (!node.active) return 0;
        uint256 currentBucket = getCurrentBucketNumber();
        if (currentBucket== node.firstBucket) return node.stakedAmount; // no penalty in first bucket
        uint256 expectedReoportCount = currentBucket - node.firstBucket;
        uint256 actualReportCount = node.reportCount;
        if (node.lastReportedBucket == currentBucket && actualReportCount > 0) {
            actualReportCount -= 1; // don't count current bucket if already reported in it, since it can't be missed
        }
        
        if (actualReportCount >= expectedReoportCount) return node.stakedAmount; // no penalty if node has reported in all expected buckets
        uint256 missedBuckets = expectedReoportCount - actualReportCount;
        uint256 penalty = missedBuckets * INACTIVITY_PENALTY;
        if (penalty >= node.stakedAmount) return 0; // full penalty if penalty exceeds or equals staked amount
        return node.stakedAmount - penalty; // effective stake
    }

    /**
     * @notice Returns the addresses of nodes in a bucket whose reported price deviates beyond the threshold
     * @param bucketNumber The bucket number to get the outliers from
     * @return Array of node addresses considered outliers
     */
    function getOutlierNodes(uint256 bucketNumber) public view returns (address[] memory) {
        BlockBucket storage bucket = blockBuckets[bucketNumber];
        if (bucket.medianPrice == 0) revert MedianNotRecorded();

        address[] memory outliers = new address[](bucket.reporters.length);
        uint256 outlierCount = 0;

        for (uint256 i = 0; i < bucket.reporters.length; i++) {
            address reporter = bucket.reporters[i];
            if (bucket.slashedOffenses[reporter]) continue; // skip already slashed nodes
            
            uint256 reportedPrice = bucket.prices[i];
            if (reportedPrice == 0) continue;

            if (_checkPriceDeviated(reportedPrice, bucket.medianPrice)) {
                outliers[outlierCount] = bucket.reporters[i];
                outlierCount++;
            }
        }

        // Resize the array to the actual number of outliers
        assembly {
            mstore(outliers, outlierCount)
        }
        
        return outliers;
    }

    //////////////////////////
    /// Internal Functions ///
    //////////////////////////

    /**
     * @notice Removes a node from the nodeAddresses array
     * @param nodeAddress The address of the node to remove
     * @param index The index of the node to remove
     */
    function _removeNode(address nodeAddress, uint256 index) internal {
        if (index >= nodeAddresses.length) revert IndexOutOfBounds();
        if (nodeAddresses[index] != nodeAddress) revert NodeNotAtGivenIndex();

        // Move the last element to the index to delete and pop the last element
        uint256 lastIndex = nodeAddresses.length - 1;
        if (index != lastIndex) {
            nodeAddresses[index] = nodeAddresses[lastIndex];
        }
        nodeAddresses.pop();

        nodes[nodeAddress].active = false; // mark node as inactive
    }

    /**
     * @notice Checks if the price deviation is greater than the threshold
     * @param reportedPrice The price reported by the node
     * @param medianPrice The average price of the bucket
     * @return True if the price deviation is greater than the threshold, false otherwise
     */
    function _checkPriceDeviated(uint256 reportedPrice, uint256 medianPrice) internal pure returns (bool) {
        uint256 priceDeviation = reportedPrice > medianPrice ? reportedPrice - medianPrice : medianPrice - reportedPrice;
        uint256 deviationBps = (priceDeviation * 10_000) / medianPrice;

        return deviationBps > MAX_DEVIATION_BPS;
    }
}
