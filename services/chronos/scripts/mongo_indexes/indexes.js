print('Creating Indexes...');

var a = db.runCommand({connectionStatus: 1}).authInfo.authenticatedUsers[0];
if (!a) {
    print('Setting feature compatibility to 7.0');
    db.getMongo().getDB("admin");
    var result = db.adminCommand({setFeatureCompatibilityVersion: "7.0"});
    print(result);
}

//NOTE: make sure every index is specified as background.  This grep will show any indexes without "background: true":
//grep "\.createIndex" indexes.js | grep -v "background: true"
db.agingevent.createIndex({"type": 1, "sourceid":1},{background: true})
db.agingevent.createIndex({"_id": 1},{background: true})
db.agingevent.createIndex({"entityid": 1, "date.timestamp": -1},{background: true})
db.agingevent.createIndex({"sourceid": 1},{background: true})

db.amountdue.createIndex({"_id": 1},{background: true})
db.amountdue.createIndex({"entityid": 1, "duedate.timestamp": 1, "statementdate.timestamp": 1},{background: true})

db.billableentity.createIndex({"_id": 1},{background: true})

db.cycleevent.createIndex({"_id": 1},{background: true})
db.cycleevent.createIndex({"entityid": 1, "enddate.timestamp": -1},{background: true})

print('...done creating indexes');
