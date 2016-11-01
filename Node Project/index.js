var bleno = require('bleno')
var Characteristic = bleno.Characteristic
var PrimaryService = bleno.PrimaryService

var BodyAnalysisDataCharacteristicUUID = '97909CF7FD2B4F2CABFE6A55AB72CFCF'
var BodyAnalysisServiceUUID = '61E3C3AD478244FB8E3DC5CE25FE88B1'

var callback

var bodyAnalysisDataCharacteristic = new Characteristic({
    uuid: BodyAnalysisDataCharacteristicUUID,
    properties: ['read', 'indicate'],
    descriptors: [ ],
    onSubscribe: function(maxValueSize, updateValueCallback) {
        console.log('Central subscribed to analysis data! Will send first data.')
        callback = updateValueCallback
        callback(new Buffer("data"))
    },
    onUnsubscribe: function() {
        console.log('Central unsubscribed from analysis data!')
        callback = null
    },
    onIndicate: function() {
        console.log('Did get indication. Will update value.')
        // On Linux, we only get one indication here
        callback(new Buffer("data"))

        // Fix:
        // setTimeout(function(){
        //     callback(new Buffer("data"))
        // }, 0)
    }
})

var bodyAnalysisService = new PrimaryService({
    uuid: BodyAnalysisServiceUUID,
    characteristics: [
        bodyAnalysisDataCharacteristic
    ]
})

var serviceUUIDs = [ bodyAnalysisService.uuid ]

bleno.on('stateChange', function (state) {
    console.log('State: ' + state)
    if (state === 'poweredOn') {
        // We start advertising the peripheral services right away
        console.log('Will start advertising...')
        bleno.startAdvertising("BLE Peripheral", serviceUUIDs, function (err) {
            if (err) {
                console.log('Advertisement error: ' + err)
            }
        })
    } else {
        console.log('Will stop advertising ...')
        bleno.stopAdvertising(function (err) {
            if (err) {
                console.log('Could not stop advertising: ' + err)
            }
        })
    }
})

bleno.on('advertisingStart', function (err) {
    if (err) {
        console.log('Could not start advertising (#1): ' + err)
    } else {
        console.log('Did start advertising...')
        bleno.setServices([ bodyAnalysisService ], function (err) {
            if (err) {
                console.log('Could not set services: ' + err)
            }
        })
    }
})

bleno.on('advertisingStartError', function (err) {
    if (err) {
        console.log('Could not start advertising (#2): ' + err)
    }
})

// Stopping advertisement
bleno.on('advertisingStop', function () {
    console.log('Advertising stopped.')
})

// Services
bleno.on('servicesSet', function (err) {
    if (err) {
        console.log('Could not set services (#1): ' + err)
    } else {
        console.log('Did set services...')
    }
})

bleno.on('servicesSetError', function (err) {
    if (err) {
        console.log('Could not set services (#1): ' + err)
    }
})

// Accept
bleno.on('accept', function (clientAddress) {
    console.log('Accepted client: ' + clientAddress)
})

bleno.on('disconnect', function (clientAddress) {
    console.log('disconnect: ' + clientAddress)
});