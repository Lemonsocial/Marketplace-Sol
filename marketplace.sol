// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTMarketplace {
  uint public offerCount;
  uint public AuctionCount;
  mapping (uint => _Offer) public offers;
  mapping (uint => uint256) internal UserTracker;
  mapping (uint => Royalties) internal RoyalTracker;
  mapping (address => uint) public userFunds;
  mapping (address => mapping(address => uint)) public TokenTracker;
  mapping (uint => auctiondata) public Auctions;
  mapping (uint => uint) public AuctionTracker;
  NFTCollection nftCollection;
  address creator;
  
  struct Royalties {
    uint royalty;
    address nftowner;
  }
  struct auctiondata{
        uint auctionid;
        address nft_owner;
        uint nftId;
        uint init_price;
        uint init_duration;
        uint duration;
        uint current_price;
        address highest_address;
        bool completed;
        bool started;
        bool cancel;
        address TokenAddress;
  }
    
  struct _Offer {
    uint offerId;
    uint id;
    address user;
    uint price;
    bool fulfilled;
    bool cancelled;
    bool isErc20;
    address Erc20Token;
  }

  event Offer(
    uint offerId,
    uint id,
    address user,
    uint price,
    bool fulfilled,
    bool cancelled
  );
  event _auctiondata(
        uint auctionid,
        address nft_owner,
        uint nftId,
        uint init_price,
        uint init_duration,
        uint duration,
        uint current_price,
        address highest_address,
        bool completed,
        bool started,
        bool cancel,
        address TokenAddress
    );
  event _make_bids(
      bool status
  );


  event OfferFilled(uint offerId, uint id, address newOwner);
  event OfferCancelled(uint offerId, uint id, address owner);
  event BidCancelled(uint offerId, uint id, address owner);
  event ClaimFunds(address user, uint amount);

  constructor(address _nftCollection) {
    nftCollection = NFTCollection(_nftCollection);
    
    creator = msg.sender;
  }
  
  function make_auction(uint duration, uint256 pric, uint nftid, address _TokenAddress, uint _At, uint r) public payable {
      Royalties storage royality = RoyalTracker[nftid];
    if(r == 0){

      }else{
          if(royality.nftowner == address(0)){
          royality.nftowner = msg.sender;
          royality.royalty = r;
        }else{
      
      }
     }
      uint256 price = pric;
      nftCollection.transferFrom(msg.sender, address(this), nftid);
      AuctionCount++;
      uint endAt = block.timestamp + (duration * 1 days);
      AuctionTracker[_At] = AuctionCount;
      Auctions[_At] = auctiondata(AuctionCount, msg.sender, nftid, price, duration, endAt, price, msg.sender, false, true, false,  _TokenAddress);
      // Auctions[AuctionCount] = auctiondata(AuctionCount, msg.sender, nftid, price, duration, endAt, price, address(this), false, true, false, false);
      // emit _auctiondata(AuctionCount, msg.sender, nftid, price, duration, endAt, price, address(this), false, true, false,  _TokenAddress);
  }

  function makeOffer(uint _id, uint _price, uint offid, bool iserc, address erc, uint r) public {
      Royalties storage royality = RoyalTracker[_id];
      if(r != 0){
        if(royality.nftowner == address(0)){
        royality.nftowner = msg.sender;
      	royality.royalty = r;
       }
      }
    nftCollection.transferFrom(msg.sender, address(this), _id);
    offerCount ++;
    offers[offid] = _Offer(offid, _id, msg.sender, _price, false, false, iserc,  erc);
    emit Offer(offerCount, _id, msg.sender, _price, false, false);
  }

  function make_bid(uint AuctionCoun) public payable {
      auctiondata storage _Auctiondata = Auctions[AuctionCoun];
     // require(_Auctiondata.auctionid == AuctionCoun, 'The Auction must exit' );
      require(_Auctiondata.nft_owner != msg.sender, 'owner can not make a bid' );
      require(!_Auctiondata.completed, 'Auction ended');
      require(!_Auctiondata.cancel, 'A cancelled offer cannot be fulfilled');
      require(_Auctiondata.duration > block.timestamp, 'Nft auction Ended');
      // require(price > _Auctiondata.current_price, 'The  amount should be more than the  NFT Price');
       require(msg.value > _Auctiondata.current_price, 'The  amount should be more than the  NFT Price');
       userFunds[_Auctiondata.highest_address] += _Auctiondata.current_price;
      _Auctiondata.highest_address = msg.sender;
      _Auctiondata.current_price = msg.value;
      _Auctiondata.duration = block.timestamp +  (_Auctiondata.init_duration * 1 days);
       emit _make_bids(true);
      }
      

   function make_bidDweb3(uint256 price,  uint AuctionCoun, address _TokenAddress) public payable {
      auctiondata storage _Auctiondata = Auctions[AuctionCoun];
      // require(_Auctiondata.auctionid == AuctionCoun, 'The Auction must exit' );
      require(_Auctiondata.nft_owner != msg.sender, 'owner can not make a bid' );
      require(!_Auctiondata.completed, 'Auction ended');
      require(!_Auctiondata.cancel, 'A cancelled offer cannot be fulfilled');
      require(_Auctiondata.duration > block.timestamp, 'Nft auction Ended');
      require(price > _Auctiondata.current_price, 'The  amount should be more than the  NFT Price');
      if(_TokenAddress != address(0)){
        uint256 amount = price;
          IERC20 token = IERC20(_TokenAddress);
      require(_Auctiondata.TokenAddress == _TokenAddress, 'Please provide the ErcToken Provided by the Seller');
      token.transferFrom(msg.sender, address(this), amount);
      TokenTracker[_TokenAddress][_Auctiondata.highest_address] += _Auctiondata.current_price;
      _Auctiondata.highest_address = msg.sender;
      _Auctiondata.current_price = price;
      _Auctiondata.duration = block.timestamp +  (_Auctiondata.init_duration * 1 days);
      emit _make_bids(true);
      }else{
       require(msg.value > _Auctiondata.current_price, 'The  amount should be more than the  NFT Price');
      userFunds[_Auctiondata.highest_address] += _Auctiondata.current_price;
      _Auctiondata.highest_address = msg.sender;
      _Auctiondata.current_price = msg.value;
      _Auctiondata.duration = block.timestamp +  (_Auctiondata.init_duration * 1 days);
      emit _make_bids(true);
      }
      

   }


  
  
  
  function fillOffer(uint _offerId, address Erc, uint price, uint uid) public payable {
       IERC20 token = IERC20(Erc);
    _Offer storage _offer = offers[_offerId];
     Royalties storage royal = RoyalTracker[_offer.offerId];
    // require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user != msg.sender, 'The owner of the offer cannot fill it');
    require(!_offer.fulfilled, 'An offer cannot be fulfilled twice');
    require(!_offer.cancelled, 'A cancelled offer cannot be fulfilled');
    
    if(_offer.isErc20 == false){
      require(msg.value == _offer.price, 'The Matic amount should match with the NFT Price');
      if(UserTracker[uid] == 1){


                  if(royal.royalty != 0){
                      userFunds[royal.nftowner] +=  (msg.value * royal.royalty) / 100;
                      uint leftFund = 100 - royal.royalty;
                      userFunds[_offer.user] += (msg.value * leftFund) / 100;
                  }else{
                    userFunds[_offer.user] = msg.value;
                  }//end of royal
          
      }else{
            if(royal.royalty != 0){
                userFunds[royal.nftowner] += (msg.value * royal.royalty) / 100;
                uint leftFund = 100 - royal.royalty;
                uint newfund = leftFund - 25;
                userFunds[_offer.user] += (msg.value * newfund) / 100;
                userFunds[creator] += (msg.value * 25) / 100;
            }else{
                // userFunds[_Auctiondata.nft_owner] = _Auctiondata.current_price;
                userFunds[_offer.user] +=  (msg.value * 25) / 100;
                userFunds[creator] += (msg.value * 25) / 100;
              
            }//end of royal
         
          UserTracker[uid] = 1;
          
      }

      nftCollection.transferFrom(address(this), msg.sender, _offer.id);
       _offer.fulfilled = true;
      emit OfferFilled(_offerId, _offer.id, msg.sender);
    }
    else if(_offer.isErc20 == true){
         require(_offer.price == price, 'Price must be equal to nft price');
         require(_offer.Erc20Token == Erc, 'The address must match payment address');
        token.transferFrom(msg.sender, address(this), price);

        //begining of Royalties and dweb2 commision
        if(UserTracker[uid] == 1){

              if(royal.royalty != 0){
                  TokenTracker[_offer.Erc20Token][royal.nftowner] += (price * royal.royalty) / 100;
                  uint leftFund = 100 - royal.royalty;
                  TokenTracker[_offer.Erc20Token][_offer.user] += (price * leftFund) / 100;
              }else{
                TokenTracker[_offer.Erc20Token][_offer.user] = price;
              }//end of royal
            
        }else{
              if(royal.royalty != 0){
                  TokenTracker[_offer.Erc20Token][royal.nftowner] += (price * royal.royalty) / 100;
                  uint leftFund = 100 - royal.royalty;
                  uint newfund = leftFund - 25;
                  TokenTracker[_offer.Erc20Token][_offer.user] += (price * newfund) / 100;
                TokenTracker[_offer.Erc20Token][creator] += ((price * 25) / 100);
              }else{
                  // userFunds[royal.nftowner] = price;
                TokenTracker[_offer.Erc20Token][royal.nftowner] += (price * 25) / 100;
                TokenTracker[_offer.Erc20Token][creator] += (price * 25) / 100;
              }//end of royal
          
            UserTracker[uid] = 1;
            
          }

        
        
        
       

        nftCollection.transferFrom(address(this), msg.sender, _offer.id);
        _offer.fulfilled = true;
        emit OfferFilled(_offerId, _offer.id, msg.sender);
      
   }
 

    // userFunds[_offer.user] += msg.value - (msg.value * 25 / 100);
    // userFunds[creator] += (msg.value * 100) / 100;


  }

  function cancelOffer(uint _offerId) public {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user == msg.sender, 'The offer can only be canceled by the owner');
    require(_offer.fulfilled == false, 'A fulfilled offer cannot be cancelled');
    require(_offer.cancelled == false, 'An offer cannot be cancelled twice');
    nftCollection.transferFrom(address(this), msg.sender, _offer.id);
    _offer.cancelled = true;
    emit OfferCancelled(_offerId, _offer.id, msg.sender);
  }

  function cancel_bid(uint _AuctionCount) public {
      auctiondata storage _Auctiondata = Auctions[_AuctionCount];
      // require(_Auctiondata.auctionid == _AuctionCount, 'The Auction must exit' );
      require(_Auctiondata.nft_owner == msg.sender, 'The offer can only be canceled by the owner');
      require(_Auctiondata.completed == false, 'An Auction cannot be Ended twice');
      require(_Auctiondata.cancel == false, 'A cancel Auction cannot be Ended');
      if(_Auctiondata.nft_owner == _Auctiondata.highest_address){
          nftCollection.transferFrom(address(this), _Auctiondata.highest_address, _Auctiondata.nftId);
      }else{
        nftCollection.transferFrom(address(this), _Auctiondata.nft_owner, _Auctiondata.nftId);
      _Auctiondata.cancel = true;
      userFunds[_Auctiondata.highest_address] += _Auctiondata.current_price;
      }
      emit BidCancelled(_Auctiondata.nftId, _Auctiondata.auctionid, msg.sender);
  }
 
  function End_auction(uint _AuctionCount, uint uid) public {
    auctiondata storage _Auctiondata = Auctions[_AuctionCount];
    Royalties storage royal = RoyalTracker[_Auctiondata.nftId];
    // require(_Auctiondata.auctionid == _AuctionCount, 'The Auction must exit' );
    require(_Auctiondata.nft_owner == msg.sender, 'The offer can only be canceled by the owner');
    require(_Auctiondata.duration < block.timestamp, 'The auctions is still on-going');
    require(_Auctiondata.cancel == false, 'A cancel Auction cannot be Ended');
    require(_Auctiondata.completed == false, 'An Auction cannot be Ended twice');
      if(_Auctiondata.nft_owner == _Auctiondata.highest_address){
           
            nftCollection.transferFrom(address(this), _Auctiondata.highest_address, _Auctiondata.nftId);

           _Auctiondata.completed = true; 
      }else{
        
        if(UserTracker[uid] == 1){
          if(royal.royalty != 0){
              userFunds[royal.nftowner] += (_Auctiondata.current_price * royal.royalty) / 100;
              uint leftFund = 100 - royal.royalty;
              userFunds[_Auctiondata.nft_owner] += (_Auctiondata.current_price * leftFund) / 100;
           }else{
             userFunds[_Auctiondata.nft_owner] = _Auctiondata.current_price;
           }//end of royal
          
        }else{
            if(royal.royalty != 0){
                userFunds[_Auctiondata.nft_owner] += (_Auctiondata.current_price * royal.royalty) / 100;
                uint leftFund = 100 - royal.royalty;
                uint newfund = leftFund - 25;
                  userFunds[_Auctiondata.nft_owner] +=  (_Auctiondata.current_price * newfund) / 100;
                userFunds[creator] += (_Auctiondata.current_price * 25) / 100;
            }else{
                // userFunds[_Auctiondata.nft_owner] = _Auctiondata.current_price;
                userFunds[_Auctiondata.nft_owner] +=  (_Auctiondata.current_price * 25) / 100;
                userFunds[creator] += (_Auctiondata.current_price * 25) / 100;
              
            }//end of royal
         
          UserTracker[uid] = 1;
          
        }
        nftCollection.transferFrom(address(this), _Auctiondata.highest_address, _Auctiondata.nftId);
        _Auctiondata.completed = true; 
      }
   
  }
  function End_dweb3auction(uint _AuctionCount, uint uid) public {
    auctiondata storage _Auctiondata = Auctions[_AuctionCount];
     Royalties storage royal = RoyalTracker[_Auctiondata.nftId];
    // require(_Auctiondata.auctionid == _AuctionCount, 'The Auction must exit' );
    require(_Auctiondata.nft_owner == msg.sender, 'The offer can only be canceled by the owner');
    require(_Auctiondata.duration < block.timestamp, 'The auctions is still on-going');
    require(_Auctiondata.cancel == false, 'A cancel Auction cannot be Ended');
    require(_Auctiondata.completed == false, 'An Auction cannot be Ended twice');
    // nftCollection.transferFrom(address(this), _Auctiondata.highest_address, _Auctiondata.nftId);

     if(_Auctiondata.nft_owner == _Auctiondata.highest_address){
       _Auctiondata.completed = true;
          nftCollection.transferFrom(address(this), _Auctiondata.highest_address, _Auctiondata.nftId);
      }else{
        //begining of Royalties and dweb2 commision
        if(UserTracker[uid] == 1){
            if(royal.royalty != 0){
                TokenTracker[_Auctiondata.TokenAddress][royal.nftowner] += (_Auctiondata.current_price * royal.royalty) / 100;
                uint leftFund = 100 - royal.royalty;
                TokenTracker[_Auctiondata.TokenAddress][_Auctiondata.nft_owner] += (_Auctiondata.current_price * leftFund) / 100;
            }else{
              TokenTracker[_Auctiondata.TokenAddress][_Auctiondata.nft_owner] = _Auctiondata.current_price;
            }//end of royal
            
          }else{
              if(royal.royalty != 0){
                  TokenTracker[_Auctiondata.TokenAddress][_Auctiondata.nft_owner] += (_Auctiondata.current_price * royal.royalty) / 100;
                  uint leftFund = 100 - royal.royalty;
                  uint newfund = leftFund - 25;
                    TokenTracker[_Auctiondata.TokenAddress][_Auctiondata.nft_owner] += (_Auctiondata.current_price * newfund) / 100;
                TokenTracker[_Auctiondata.TokenAddress][creator] += (_Auctiondata.current_price * 25) / 100;
              }else{
                  // userFunds[_Auctiondata.nft_owner] = _Auctiondata.current_price;
                  TokenTracker[_Auctiondata.TokenAddress][_Auctiondata.nft_owner] += (_Auctiondata.current_price * 25) / 100;
                TokenTracker[_Auctiondata.TokenAddress][creator] += (_Auctiondata.current_price * 25) / 100;
                
              }//end of royal
          
            UserTracker[uid] = 1;
            
          }

        
        
        
        _Auctiondata.completed = true;

         nftCollection.transferFrom(address(this), _Auctiondata.highest_address, _Auctiondata.nftId);
      
      
      }
       
        
   
  }

  function claimFunds() public {
    require(userFunds[msg.sender] > 0, 'This user has no funds to be claimed');
    payable(msg.sender).transfer(userFunds[msg.sender]);
    emit ClaimFunds(msg.sender, userFunds[msg.sender]);
    userFunds[msg.sender] = 0;    
  }
  
  function WithdrawErc20(address a) public {
     require(TokenTracker[a][msg.sender] > 0, 'This user has no funds to be claimed');
     
            IERC20(a).transfer(
                msg.sender,
                TokenTracker[a][msg.sender]
            );
             TokenTracker[a][msg.sender] = 0;
  }
 
  // Fallback: reverts if Ether is sent to this smart-contract by mistake
  fallback () external {
    revert();
  }
  
}