pragma solidity ^0.5.16;
// COMP7408 - Assignment
// Tse Chun Kit 3035416818
 
 
contract flipCoin { 
    address payable public banker;
    address payable[] public participants;
    bytes32[] public hashs;
    uint public result;
    uint[] private values;
    uint public balance;
    uint[] private hashSubmiTimes;
    uint public transactionTime;
    uint private lastTransactionTime;
    uint[] private transactionTimes; // private
    uint[] private selectedTrasactionTimes; //private

    struct record{
        address playerA;
        bytes32 AHashvalue;
        uint ASubmitTime;
        uint AValue;
        address playerB;
        bytes32 BHashvalue;
        uint BSubmitTime;
        uint BValue;
        address winner;
        uint executedTime;
    }

    mapping(uint => record) public records;
    
   
    constructor() public{
        banker = msg.sender;
    }

    function joinGame() public payable returns(uint){
        require(msg.value == 10 ether,"Participant should send 10 ehters to join game"); // require 10 ether sent by participants
        require(participants.length < 2,"More than 2 users are not allowed"); // not more than 2 players to join the game
        if (participants.length > 0){
            require(participants[0]!= msg.sender,"You joined Game already"); // The first  
        }
        balance = balance + msg.value;
        participants.push(msg.sender);
        uint value = random();
        bytes32 hash = keccak256(abi.encodePacked(value));
        hashs.push(hash);
        values.push(value);
        hashSubmiTimes.push(now);
        return value;
    }

    
    function random() private view returns (uint) {
        // This function genrate a large number.
        return uint(keccak256(abi.encodePacked(block.difficulty, now, hashs)));
    }

    function pickWinner() public {
        require(values.length > 1,"Not enough participant joined");
        uint i;
        uint sum = 0;
        for(i = 0; i < values.length; i++){
            require(keccak256(abi.encodePacked(values[i])) == hashs[i],"Someone cheating"); // verify the value with hash value
            sum = sum + values[i];
            }
        uint index = sum % participants.length;
        
        participants[index].transfer(address(this).balance*95/100); // winner take 95% of deposits
        transactionTime=now;
        banker.transfer(address(this).balance); // banker get 5% service fee

        for(i = 0; i < values.length; i++){
            if (i!=index){
                participants[i].transfer(0); // notify loser players by sending 0 dollar
            }
        }
        
        commitRecord(participants[index]);
        reSetContract(); // Re-set the contract to default value
    }

    function commitRecord(address winner) private{
        // This function save all values, transaction records.
        transactionTimes.push(transactionTime);
        lastTransactionTime = transactionTime;
        records[transactionTime]=record(participants[0],hashs[0],hashSubmiTimes[0],values[0],participants[1],hashs[1],hashSubmiTimes[1],values[1],winner,transactionTime);
    }


    function queryRecords() public returns(
        address[] memory, uint[] memory,
        address[] memory, uint[] memory,
        address[] memory, uint[] memory){
        // This function designed for banker to query transactions over one day
        // This function returns Player A addresses, Player A Values, Player B addresses, Player B Values, Winner's addresses, transaction times
        // in a array format 
        require(transactionTimes.length > 0,"No record can be found!!!");
        require(msg.sender == banker,"Only banker is allowed to view");
        selectedTrasactionTimes = new uint[](0); // reset all old records
        greaterThan();
        address[] memory _playerA = new address[](selectedTrasactionTimes.length);
        uint[] memory _AValue = new uint[](selectedTrasactionTimes.length);
        address[] memory _playerB = new address[](selectedTrasactionTimes.length);
        uint[] memory _BValue = new uint[](selectedTrasactionTimes.length);
        address[] memory _winner = new address[](selectedTrasactionTimes.length);
        uint[] memory _executedTime = new uint[](selectedTrasactionTimes.length);

        for (uint i = 0; i < selectedTrasactionTimes.length; i++) {
            record storage _record = records[selectedTrasactionTimes[i]];
            _playerA[i] = _record.playerA;
            _AValue[i]=_record.AValue;
            _playerB[i]=_record.playerB;
            _BValue[i]=_record.BValue;
            _winner[i]=_record.winner;
            _executedTime[i] = _record.executedTime;
        }

        return (
            _playerA,
            _AValue,
            _playerB,
            _BValue,
            _winner,
            _executedTime);
    }

    function queryRecord() public returns(
        address playerA, bytes32 AHashvalue, uint ASubmitTime, uint AValue,
        address playerB, bytes32 BHashvalue, uint BSubmitTime, uint BValue,
        address winner, uint executedTime){
        // This function designed for participant to query last transaction for verification purpose
        
        require(transactionTimes.length > 0,"No record can be found!!!");
        
        uint index = transactionTimes[transactionTimes.length-1];
        return (
            records[index].playerA,
            records[index].AHashvalue,
            records[index].ASubmitTime,
            records[index].AValue,
            records[index].playerB,
            records[index].BHashvalue,
            records[index].BSubmitTime,
            records[index].BValue,
            records[index].winner,
            records[index].executedTime);
    }


    function greaterThan() private {
        uint v= now - 60*60*24;
    
        for (uint i = 0; i < transactionTimes.length; i++) {
            uint _v = transactionTimes[i];
            if (_v > v) {
                selectedTrasactionTimes.push(_v);
            }
        }
    }

    function reSetContract() private{
        // This function resets the contract default value to zero and ready for next game
        participants = new address payable[](0);
        hashs = new bytes32[](0);
        values = new uint[](0);
    }
    
} 