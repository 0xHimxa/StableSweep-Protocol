// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StableToken} from "src/StableToken.sol";
import {RaffileEngine} from "src/engine.sol";
import {EngineConfig} from "script/config.s.sol";
import {DeployEngine} from "script/deploy.s.sol";
import {RaffileEngine} from "src/engine.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Handler} from "test/invariant/handler.sol";

contract InvariantsTest is StdInvariant, Test {
    StableToken stableToken;
    RaffileEngine engine;
    EngineConfig.EngineParams config;
 Handler handler;
   

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        DeployEngine deploy = new DeployEngine();
        (config, stableToken, engine) = deploy.run();
          handler = new Handler(address(engine), address(stableToken));
 targetContract(address(handler));
     
    }




function invariant_ticketConservation() external view  {
    uint256 total;

    for (uint256 i = 0; i < handler.actorCount(); i++) {
      console.log(handler.ticketBalance(handler.actors(i)), "actors balance");  
        total += handler.ticketBalance(handler.actors(i));
    }

console.log(total,"total handler tickets");
console.log( engine.activeTicket(),"engine record");
   // assertEq(cost , engine.totalTicketCost());
    assertEq(total, engine.activeTicket());

}



function invariant_balances() external view{

assertEq(stableToken.totalSupply(), handler.mintedAmount());
assert(address(stableToken).balance == handler.depositedEth());


}





}