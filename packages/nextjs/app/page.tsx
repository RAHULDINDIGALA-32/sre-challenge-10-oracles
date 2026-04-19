"use client";

import Image from "next/image";
import Link from "next/link";
import { Address } from "@scaffold-ui/components";
import type { NextPage } from "next";
import { hardhat } from "viem/chains";
import { useAccount } from "wagmi";
import {
  BeakerIcon,
  BugAntIcon,
  ChartBarIcon,
  MagnifyingGlassIcon,
  ScaleIcon,
  ShieldCheckIcon,
} from "@heroicons/react/24/outline";
import { useTargetNetwork } from "~~/hooks/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const { targetNetwork } = useTargetNetwork();

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5 max-w-4xl">
          {/* HEADER */}
          <h1 className="text-center">
            <span className="block text-2xl mb-2">SpeedRunEthereum</span>
            <span className="block text-4xl font-bold">Challenge 10 - 🔗 Oracle Challenge</span>
            <span className="block text-lg mt-2">
              Build decentralized oracle systems and compare whitelist, staking-based, and optimistic oracle
              architectures.
            </span>
          </h1>

          {/* CONNECTED WALLET */}
          <div className="flex justify-center items-center space-x-2 flex-col mt-6">
            <p className="my-2 font-medium text-lg">Connected Wallet:</p>
            <Address
              address={connectedAddress}
              chain={targetNetwork}
              blockExplorerAddressLink={
                targetNetwork.id === hardhat.id ? `/blockexplorer/address/${connectedAddress}` : undefined
              }
            />
          </div>

          {/* HERO IMAGE */}
          <div className="flex flex-col items-center justify-center mt-10">
            <Image
              src="/hero.png"
              width="727"
              height="231"
              alt="Oracle Challenge banner"
              className="rounded-xl border-4 border-primary"
            />
          </div>

          {/* CONTENT */}
          <div className="mt-10 space-y-6 text-lg">
            <p>
              🔗 In this challenge you will build your own <strong>decentralized oracle systems</strong>: the
              infrastructure smart contracts use to bring real-world information on-chain.
            </p>

            <p>The system implemented explores three core oracle patterns:</p>

            <ul className="list-disc list-inside ml-4 space-y-1">
              <li>Whitelist Oracle for simple, fast, trusted data feeds</li>
              <li>Staking Oracle with ORA staking, rewards, inactivity penalties, and slashing</li>
              <li>Optimistic Oracle with assertions, proposals, disputes, and settlements</li>
              <li>Median-based price aggregation and stale data filtering</li>
              <li>Challenge-response dispute resolution for real-world event outcomes</li>
              <li>Testnet deployment and contract verification workflow</li>
            </ul>

            <p>
              The goal is to understand the core oracle trade-offs: <strong>speed</strong>,{" "}
              <strong>decentralization</strong>, <strong>cost</strong>, <strong>latency</strong>, and{" "}
              <strong>security</strong>. Each oracle design solves the same problem from a different angle: how can a
              blockchain trust information that came from outside the blockchain?
            </p>
          </div>

          {/* ORACLE ARCHITECTURES */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">🏛️ The Three Oracle Designs</h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-base-100 border border-base-300 rounded-lg p-5">
                <ShieldCheckIcon className="h-8 w-8 text-primary mb-3" />
                <h3 className="text-xl font-bold">Whitelist Oracle</h3>
                <p className="mt-2">
                  The owner whitelists trusted SimpleOracle nodes, collects fresh price reports, and returns the median
                  price.
                </p>
              </div>

              <div className="bg-base-100 border border-base-300 rounded-lg p-5">
                <ChartBarIcon className="h-8 w-8 text-primary mb-3" />
                <h3 className="text-xl font-bold">Staking Oracle</h3>
                <p className="mt-2">
                  Nodes stake ORA, report once per bucket, earn rewards for participation, and can be slashed for bad
                  reports.
                </p>
              </div>

              <div className="bg-base-100 border border-base-300 rounded-lg p-5">
                <ScaleIcon className="h-8 w-8 text-primary mb-3" />
                <h3 className="text-xl font-bold">Optimistic Oracle</h3>
                <p className="mt-2">
                  Anyone can assert an event, propose an outcome, dispute it with a bond, and wait for the decider to
                  settle.
                </p>
              </div>
            </div>
          </div>

          {/* WHITELIST ORACLE */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">🔍 Checkpoint 1: Whitelist Oracle</h2>

            <p>
              The whitelist oracle starts with the simplest architecture. Each <strong>SimpleOracle</strong> represents
              one trusted data source, and <strong>WhitelistOracle</strong> aggregates the active feeds.
            </p>

            <pre className="bg-base-200 p-4 rounded-xl overflow-auto text-sm">
              {`SimpleOracle A -> 100
SimpleOracle B -> 102
SimpleOracle C -> 98

WhitelistOracle -> sort [98, 100, 102] -> median = 100`}
            </pre>

            <ul className="list-disc list-inside ml-4 space-y-1">
              <li>Add and remove trusted oracle nodes</li>
              <li>Filter stale reports using the freshness window</li>
              <li>Aggregate prices with a median to resist outliers</li>
              <li>Query active oracle nodes from the frontend</li>
            </ul>
          </div>

          {/* STAKING ORACLE */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">💰 Checkpoint 2: Staking Oracle</h2>

            <p>
              The staking oracle replaces trusted operators with <strong>economic incentives</strong>. Nodes register by
              staking ORA, report prices during block buckets, and earn rewards for honest participation.
            </p>

            <pre className="bg-base-200 p-4 rounded-xl overflow-auto text-sm">
              {`bucketNumber = block.number / BUCKET_WINDOW + 1

reported prices -> recordBucketMedian(bucket)
node report vs median -> slash if deviation > MAX_DEVIATION_BPS`}
            </pre>

            <ul className="list-disc list-inside ml-4 space-y-1">
              <li>Register nodes by staking ORA tokens</li>
              <li>Report one price per bucket</li>
              <li>Finalize past buckets by recording their median</li>
              <li>Claim ORA rewards based on report count</li>
              <li>Slash outlier nodes and reward slashers</li>
              <li>Apply inactivity penalties for missed reports</li>
            </ul>
          </div>

          {/* OPTIMISTIC ORACLE */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">🧠 Checkpoints 3-6: Optimistic Oracle</h2>

            <p>
              The optimistic oracle handles binary questions about real-world events. It assumes proposals are correct
              unless someone disputes them, making it efficient when disputes are rare.
            </p>

            <pre className="bg-base-200 p-4 rounded-xl overflow-auto text-sm">
              {`asserter -> assertEvent(description, startTime, endTime) + reward
proposer -> proposeOutcome(assertionId, true/false) + bond
disputer -> disputeOutcome(assertionId) + matching bond
decider  -> settleAssertion(assertionId, resolvedOutcome)
winner   -> claim reward + bond refund`}
            </pre>

            <p>The optimistic workflow supports:</p>

            <ul className="list-disc list-inside ml-4 space-y-1">
              <li>Creating assertions with reward-backed time windows</li>
              <li>Posting bonded proposals for true or false outcomes</li>
              <li>Disputing proposals during the dispute window</li>
              <li>Claiming undisputed rewards after the dispute window expires</li>
              <li>Settling disputed assertions through the decider contract</li>
              <li>Querying assertion state and final resolution</li>
            </ul>
          </div>

          {/* SIMULATIONS AND TESTING */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">🧪 Testing and Live Simulations</h2>

            <p>Use the checkpoint tests to verify each implementation as you build:</p>

            <pre className="bg-base-200 p-4 rounded-xl overflow-auto text-sm">
              {`yarn test --grep "Checkpoint1"
yarn test --grep "Checkpoint2"
yarn test --grep "Checkpoint4"
yarn test --grep "Checkpoint5"
yarn test --grep "Checkpoint6"`}
            </pre>

            <p>Then run the simulations to watch oracle behavior in motion:</p>

            <pre className="bg-base-200 p-4 rounded-xl overflow-auto text-sm">
              {`yarn simulate:whitelist
yarn simulate:staking
yarn simulate:optimistic

AUTO_SLASH=true yarn simulate:staking`}
            </pre>
          </div>

          {/* COMPARISON TABLE */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">⚖️ Oracle Comparison and Trade-offs</h2>

            <div className="overflow-x-auto">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>Aspect</th>
                    <th>Whitelist</th>
                    <th>Staking</th>
                    <th>Optimistic</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>Speed</td>
                    <td>Fast</td>
                    <td>Medium</td>
                    <td>Slow</td>
                  </tr>
                  <tr>
                    <td>Security</td>
                    <td>Low, trusted authority</td>
                    <td>High, economic incentives</td>
                    <td>High, dispute resolution</td>
                  </tr>
                  <tr>
                    <td>Decentralization</td>
                    <td>Low</td>
                    <td>High</td>
                    <td>Depends on decider</td>
                  </tr>
                  <tr>
                    <td>Cost</td>
                    <td>Low</td>
                    <td>Medium</td>
                    <td>High</td>
                  </tr>
                  <tr>
                    <td>Complexity</td>
                    <td>Simple</td>
                    <td>Medium</td>
                    <td>Complex</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <p>
              Whitelist oracles are useful when trusted intermediaries are acceptable. Staking oracles work well for
              DeFi systems that need recurring price updates. Optimistic oracles shine when questions are flexible,
              subjective, or expensive to answer continuously.
            </p>
          </div>

          {/* CONTRACT ADDRESSES */}
          <div className="mt-10 space-y-6 text-lg">
            <h2 className="text-2xl font-bold">🚀 Deployment</h2>

            <p>The smart contracts can be deployed on Sepolia. Replace these placeholders after deployment:</p>

            <p className="font-semibold">
              Whitelist Oracle:{" "}
              <Link
                href="https://sepolia.etherscan.io/address/0x2BACc689F90031420D997027FE25bB3080efD784"
                passHref
                className="link"
              >
                0x2BACc689F90031420D997027FE25bB3080efD784
              </Link>
              <br />
              Staking Oracle:{" "}
              <Link
                href="https://sepolia.etherscan.io/address/0xBabbdab28Df196338b776642c3E680a442764B46"
                passHref
                className="link"
              >
                0xBabbdab28Df196338b776642c3E680a442764B46
              </Link>
              <br />
              Optimistic Oracle:{" "}
              <Link
                href="https://sepolia.etherscan.io/address/0x3c6D7C62e5E0DACC3f062f16Ae81084D8FD539ad"
                passHref
                className="link"
              >
                0x3c6D7C62e5E0DACC3f062f16Ae81084D8FD539ad
              </Link>
              <br />
              Decider:{" "}
              <Link
                href="https://sepolia.etherscan.io/address/0xEd1D114bb7485F01ec3D466acFd9a6a64cF8D2AB"
                passHref
                className="link"
              >
                0xEd1D114bb7485F01ec3D466acFd9a6a64cF8D2AB
              </Link>
              <br />
              ORA Token:{" "}
              <Link
                href="https://sepolia.etherscan.io/address/0x0E8fB5b3eFA697CcC2AB4ee6744425B046Fa2322"
                passHref
                className="link"
              >
                0x0E8fB5b3eFA697CcC2AB4ee6744425B046Fa2322
              </Link>
            </p>

            <p>Deployment and verification commands:</p>

            <pre className="bg-base-200 p-4 rounded-xl overflow-auto text-sm">
              {`yarn deploy --network sepolia
yarn verify --network sepolia`}
            </pre>

            <p>
              Built using <strong>Scaffold-ETH 2, Next.js, Wagmi, Viem, RainbowKit, and Hardhat</strong>.
            </p>
          </div>

          <p className="text-center text-lg mt-16">
            <a
              href="https://speedrunethereum.com/challenge/oracles"
              target="_blank"
              rel="noreferrer"
              className="underline"
            >
              SpeedRunEthereum.com
            </a>
          </p>
        </div>

        {/* FOOTER */}
        <div className="grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col md:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <BugAntIcon className="h-8 w-8 fill-secondary" />
              <p>
                Interact with contracts in{" "}
                <Link href="/debug" passHref className="link">
                  Debug Contracts
                </Link>
                .
              </p>
            </div>

            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <BeakerIcon className="h-8 w-8 fill-secondary" />
              <p>
                Try the oracle flows in{" "}
                <Link href="/whitelist" passHref className="link">
                  Whitelist
                </Link>
                ,{" "}
                <Link href="/staking" passHref className="link">
                  Staking
                </Link>
                , and{" "}
                <Link href="/optimistic" passHref className="link">
                  Optimistic
                </Link>
                .
              </p>
            </div>

            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" />
              <p>
                Inspect transactions on{" "}
                <Link href="https://sepolia.etherscan.io" passHref className="link">
                  Etherscan
                </Link>
                .
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
