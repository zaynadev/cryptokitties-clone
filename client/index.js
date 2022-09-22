var web3 = new Web3(window.ethereum);

var instance;
var user;
var contractAddress = "0x388662564Ad21f2AF1CFfDDf88e311e4EE4CD51f";

$(document).ready(function(){
    if (window.ethereum) {
            window.ethereum.request({ method: 'eth_requestAccounts' }).then(function(accounts){
                user = accounts[0];
                instance = new web3.eth.Contract(abi, contractAddress, {from: user});
                console.log(instance);

                instance.events.Birth().on('data', function(event){
                    console.log(event);
                    let owner = event.returnValues.owner;
                let kittyId = event.returnValues.kittyId;
                let mumId = event.returnValues.mumId;
                let dadId = event.returnValues.dadId;
                let genes = event.returnValues.genes
                $("#kittyCreation").css("display", "block");
                $("#kittyCreation").text("owner:" + owner
                                        +" kittyId:" + kittyId
                                        +" mumId:" + mumId
                                        +" dadId:" + dadId
                                        +" genes:" + genes)
            }).on('error', console.error);
            });
        }else{
            console.log('Metamask not installed!');

      }

});


function createKitty(){
    var dnaStr = getDna();
    console.log("dna: ", dnaStr)
    instance.methods.createKittyGen0(dnaStr).send({}, function(error, tnxHash){
        if(error) 
            console.log(err);
        else
            console.log(tnxHash);
    });
}