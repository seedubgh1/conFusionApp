//function printstuff(stuff){
//	console.log(stuff);
//};

function mainfunction(anotherfunction,value){
	anotherfunction(value);
};

mainfunction(function(stuff) {	console.log(stuff);},'Oatman');

var printBacon = function() {
	console.log('bacon is healthy, don"t believe the doctors');
}

printBacon();
