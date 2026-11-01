const aws = require('aws-sdk');
const s3 = new aws.S3();
		
exports.handler = async (event, context) => {
    console.log('Enter handler function');
    console.log('-- Env: ' + process.env.Env);
    console.log('-- BucketName: ' + process.env.BucketName);
    console.log('-- Prefix: ' + process.env.Prefix);
    console.log('-- ObjectAgeMinutesMin: ' + process.env.ObjectAgeMinutesMin);
    console.log('-- ObjectAgeMinutesMax: ' + process.env.ObjectAgeMinutesMax);
    console.log('-- RunDate: ' + process.env.RunDate);

    var now = process.env.RunDate == "null" ? new Date() : new Date(process.env.RunDate);
    console.log('-- now: ' + now);
    
    var params = {
        Bucket: process.env.BucketName,
        Prefix: process.env.Prefix
    };
    
    var oldObjects = [];
    
    await s3.listObjectsV2(params, (err, data) => {
        if (err) {
            console.log(err, err.stack);
        }
        else {
            console.log('Scanning S3 objects');

            data.Contents.forEach(obj => {
                if (obj.Size > 0 ) {
                    console.log('obj.Key: ' + obj.Key);
                    console.log(' -- LastModified: ' + obj.LastModified);
                    const minutesOld = (now.getTime() - obj.LastModified.getTime()) / 60000;   // 60 seconds * 1000 milliseconds = 1 minute
                    console.log(' -- minutesOld: ' + minutesOld);
                    if (minutesOld > process.env.ObjectAgeMinutesMin && minutesOld < process.env.ObjectAgeMinutesMax) {
                        console.log(' *** FOUND old object');
                        oldObjects.push({ objectKey: obj.Key, lastModified: obj.LastModified, minutesOld: minutesOld });
                    }
                }
            }); 
            
            console.log('oldObjects: ' + JSON.stringify(oldObjects));
        }
    }).promise();
    
    const response = {
        statusCode: 200,
        found: oldObjects.length > 0 ? 'true' : 'false',
        oldObjects: JSON.stringify(oldObjects)
    };
    
    return response;
};
