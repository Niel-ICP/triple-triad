// SPDX-License-Identifier: Unlicensed
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8;


contract TripleTriad {
    using Strings for uint8;

    uint randNonce = 42; 
    
    
    struct Card {
       // uint8[4] sides; //0 = left; 1 = up; 2 = right; 3 = down
       uint8 left;
       uint8 up;
       uint8 right;
       uint8 down;
    }

    struct Grid {
        uint8[9] squares;
        bool[9] free;
        bool[9] redOrBlue; //false for red | true for blue
        address blue;
        address red;
        uint8 blueCards;
        uint8 redCards;
        address turn;
        address winner;
    }


    Card[] public cards;
    Grid[] public grids;

    uint8 public gridSize = 9;
    address public zero = 0x0000000000000000000000000000000000000000;
    mapping(address => bool) waitingToPlay;
    mapping(address => uint32) ownerOfCard;
    mapping(uint32 => bool) cardInHand;
    mapping(address => uint8[5]) public cardsInHand;
    mapping(uint32 => bool) cardPlayed;
    mapping(uint32 => uint8) public cardId;
    uint32 totalCards;
    string public baseURI;

    mapping(address => uint32) gridBeingPlayed;

    bool cardsDefined;
    uint32 totalGrids;

    function defineCards() public {
        require(!cardsDefined);
        createCard(0, 0, 0, 0);
        createCard(5, 5, 5, 5);
        createCard(2, 7, 3, 7);
        createCard(2, 8, 3, 3);
        createCard(1, 3, 2, 9);
        createCard(4, 2, 6, 3);
        createCard(1, 2, 7, 5);
        createCard(6, 6, 1, 3);
        createCard(8, 1, 8, 1);
        cardsDefined = true;
    }

    function randomizeCards() public {
        for(uint8 i; i < 5; i++) {
            cardsInHand[msg.sender][i] = uint8(randMod(cards.length));
        }
    }

    function start() public {
        require(!waitingToPlay[msg.sender], "You are already waiting to play");
        gridBeingPlayed[msg.sender] = totalGrids;
        grids.push(Grid([0,0,0,0,0,0,0,0,0],
        [true, true, true, true, true, true, true, true, true],
        [false, false, false, false, false, false, false, false, false],
        msg.sender, zero, 0, 0, msg.sender, zero));
        totalGrids++;
        waitingToPlay[msg.sender] = true;
    }

    function join(address _player) public {
        require(waitingToPlay[_player], "Player is not waiting to play");
        require(_player != msg.sender, "... sir, this is your address");
        gridBeingPlayed[msg.sender] = gridBeingPlayed[_player];
        grids[gridBeingPlayed[msg.sender]].red = msg.sender;
        waitingToPlay[_player] = false;
    }

    function playCard(uint8 _card, uint8 _square) public {
        /*require(!cardPlayed[_card]);
        cardPlayed[_card] = true;*/ // !!WILL BE USED WHEN EACH CARD IS AN NFT!!
        require(_square < 9, "Not viable square");
        uint32 _grid = gridBeingPlayed[msg.sender];
        require(grids[_grid].free[_square], "Square is not empty");
        require(grids[_grid].red != zero, "game has not started yet");
        require(grids[_grid].turn == msg.sender, "It's not your turn");
        bool checkMinus1 = _square == 1 || _square == 2 || _square == 4 || _square == 5 || _square == 7 || _square == 8 ? true : false; //1, 2, 4, 5, 7, 8
        bool checkMinus3 = _square == 3 || _square == 4 || _square == 5 || _square == 6 || _square == 7 || _square == 8 ? true : false; //3, 4, 5, 6, 7, 8
        bool checkPlus1 = _square == 0 || _square == 1 || _square == 3 || _square == 4 || _square == 6 || _square == 7 ? true : false; //0, 1, 3, 4, 6, 7
        bool checkPlus3 = _square == 0 || _square == 1 || _square == 2 || _square == 3 || _square == 4 || _square == 5 ? true : false; //0, 1, 2, 3, 4, 5
        //uint8 _cardId = cardId[_card]; !!WILL BE USED WHEN EACH CARD IS AN NFT!!
        uint8 _cardId = _card;
        grids[_grid].free[_square] = false;
        grids[_grid].squares[_square] = _cardId;
        uint8 _cardsFlipped;
        bool _redOrBlue = grids[_grid].blue == msg.sender ? true : false;
        grids[_grid].turn = _redOrBlue == false ? grids[_grid].blue : grids[_grid].red;
        if(checkMinus1 && !grids[_grid].free[_square-1] && cards[_cardId].left > cards[grids[_grid].squares[_square-1]].right && grids[_grid].redOrBlue[_square-1] != _redOrBlue) {
            grids[_grid].redOrBlue[_square-1] = !grids[_grid].redOrBlue[_square-1];
            _cardsFlipped++;
        }        
        if(checkMinus3 && !grids[_grid].free[_square-3] && cards[_cardId].up > cards[grids[_grid].squares[_square-3]].down && grids[_grid].redOrBlue[_square-3] != _redOrBlue) {
            grids[_grid].redOrBlue[_square-3] = !grids[_grid].redOrBlue[_square-3];
            _cardsFlipped++;
        }
        if(checkPlus1 && !grids[_grid].free[_square+1] && cards[_cardId].right > cards[grids[_grid].squares[_square+1]].left && grids[_grid].redOrBlue[_square+1] != _redOrBlue) {
            grids[_grid].redOrBlue[_square+1] = !grids[_grid].redOrBlue[_square+1];
            _cardsFlipped++;
        } 
        if(checkPlus3 && !grids[_grid].free[_square+3] && cards[_cardId].down > cards[grids[_grid].squares[_square+3]].up && grids[_grid].redOrBlue[_square+3] != _redOrBlue) {
            grids[_grid].redOrBlue[_square+3] = !grids[_grid].redOrBlue[_square+3];
            _cardsFlipped++;
        } 
        grids[_grid].redOrBlue[_square] = _redOrBlue;
        if(!_redOrBlue) {
            grids[_grid].redCards += 1 + _cardsFlipped;
            grids[_grid].blueCards -= _cardsFlipped;
        }
        if(_redOrBlue) {
            grids[_grid].blueCards += 1 + _cardsFlipped;
            grids[_grid].redCards -= _cardsFlipped;
        }
        if(grids[_grid].redCards + grids[_grid].blueCards == 9) {
            grids[_grid].winner = grids[_grid].redCards > grids[_grid].blueCards ? grids[_grid].red : grids[_grid].blue;
            grids[_grid].turn = zero;
        }
    }

    function createCard(uint8 left, uint8 up, uint8 right, uint8 down) public /*onlyOwner*/ {
        cards.push(Card(left, up, right, down));
    }

    function getGridColors() public view returns(bool[3] memory, bool[3] memory, bool[3] memory) {
        uint32 _grid = gridBeingPlayed[msg.sender];
        bool[3] memory topLine;
        bool[3] memory midLine;
        bool[3] memory botLine;
        topLine[0] = grids[_grid].redOrBlue[0];
        topLine[1] = grids[_grid].redOrBlue[1];
        topLine[2] = grids[_grid].redOrBlue[2];
        midLine[0] = grids[_grid].redOrBlue[3];
        midLine[1] = grids[_grid].redOrBlue[4];
        midLine[2] = grids[_grid].redOrBlue[5];
        botLine[0] = grids[_grid].redOrBlue[6];
        botLine[1] = grids[_grid].redOrBlue[7];
        botLine[2] = grids[_grid].redOrBlue[8];
        return(topLine, midLine, botLine);
    }

    function getGridCards() public view returns(uint8[3] memory, uint8[3] memory, uint8[3] memory) {
        uint32 _grid = gridBeingPlayed[msg.sender];
        uint8[3] memory topLine;
        uint8[3] memory midLine;
        uint8[3] memory botLine;
        topLine[0] = grids[_grid].squares[0];
        topLine[1] = grids[_grid].squares[1];
        topLine[2] = grids[_grid].squares[2];
        midLine[0] = grids[_grid].squares[3];
        midLine[1] = grids[_grid].squares[4];
        midLine[2] = grids[_grid].squares[5];
        botLine[0] = grids[_grid].squares[6];
        botLine[1] = grids[_grid].squares[7];
        botLine[2] = grids[_grid].squares[8];
        return(topLine, midLine, botLine);
    }

    function getGridInfo(uint32 _grid) public view returns (uint8[9] memory, bool[9] memory, bool[9] memory) {
        return(grids[_grid].squares, grids[_grid].free, grids[_grid].redOrBlue);
    }

    function checkCard(uint8 _cardId) public view returns (uint8[4] memory) {
        uint8[4] memory _cardValues = [cards[_cardId].left, cards[_cardId].up, cards[_cardId].right, cards[_cardId].down];
        return _cardValues;
    }

    function checkFree(uint32 _grid, uint8 _square) public view returns (bool) {
        return grids[_grid].free[_square];
    }

    function checkColor(uint32 _grid, uint8 _square) public view returns (bool) {
        return grids[_grid].redOrBlue[_square];
    }

    function checkSquare(uint32 _grid, uint8 _square) public view returns (bool, uint8) {
        return(grids[_grid].free[_square], grids[_grid].free[_square] == true ? 0 : grids[_grid].squares[_square]);
    }


    function checkSquareURI(uint32 _grid, uint8 _square) public view returns (string memory) {
        return cardURI(grids[_grid].squares[_square]);
    }

    function checkIfWaiting(address _player) public view returns (string memory) {
        return waitingToPlay[_player] == true ? "Player is waiting to play." : "Player is not waiting to play.";
    }

    function cardURI(uint8 _id) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    /*
0 = right, down +1, +3
1 = left, right, down -1, +1, +3
2 = left, down -1, +3
3 = up, right, down -3, +1, +3
4 = left, up, right, down -1, -3, +1, +3
5 = left, up, down -1, -3, +3
6 = up, right -3, +1
7 = left, up, right -1, -3, +1
8 = left, up -1, -3


//+1 = right
//-1 = left
//-3 = up
//+3 = down */
    function randMod(uint _modulus) internal returns(uint){
        // increase nonce
        randNonce++; 
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }
}
