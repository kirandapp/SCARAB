var fs = require('fs');
for (var i = 1; i<=4; i++ ) {
    var json = {}
    json.name = "Token #" + i;
    json.description = "This is the description for token #" + i;
    json.image = "ipfs://bafybeie4x4fkepc3km4osop427lesjb5klp7hxxlauu33dflrgo4s3tuci" + i + ".jpg";

    fs.writeFileSync('' + i, JSON.stringify(json));
}