// FUNCTIONS

// helper function, https://stackoverflow.com/questions/5767325/how-can-i-remove-a-specific-item-from-an-array
function removeItemOnce(arr, value) {
	var index = arr.indexOf(value);
	if (index > -1) {
		arr.splice(index, 1);
	}
	return arr;
}

//general function for grabbing parameter from a URL
function getParamFromURL( name ) {
  name = name.replace(/[\[]/,"\\[").replace(/[\]]/,"\\]");
  var regexS = "[\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return "";
  else
    return results[1];
}

//create random code for final message
//start code creation script
function randLetter() {
  var a_z = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var int =  Math.floor((Math.random() * a_z.length));
  var rand_letter = a_z[int];
  return rand_letter;
};

function createCode(secretCode,codelength_begin=7,codelength_end=10) {
	var code = "";
	for (var i = 0; i < codelength_begin; i++){
		code = code.concat(randLetter());
	};

	code = code.concat(secretCode);

	for (var i = 0; i < codelength_end; i++){
		code = code.concat(randLetter());
	}

	return code
}

