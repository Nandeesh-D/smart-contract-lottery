// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";
import {FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        //just create helperConfing contracts and refer them
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();

        if (networkConfig.subscriptionId == 0) {
            //create new subscription
            CreateSubscription subscription = new CreateSubscription();
            //setting subscription id to our network config
            (
                networkConfig.subscriptionId,
                networkConfig.vrfCoordinator
            ) = subscription.createSubscription(networkConfig.vrfCoordinator);

            //fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link
            );
        }
        vm.startBroadcast();

        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );

        vm.stopBroadcast();

        //adding consumer to subscription address
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId
        );
        return (raffle, helperConfig);
    }
}
