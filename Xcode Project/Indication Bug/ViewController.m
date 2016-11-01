//
//  ViewController.m
//  Indication Bug
//
//  Created by Marcus Mattsson on 01/11/16.
//  Copyright (c) 2016 mattsson. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *selectedPeripheral;
@property (nonatomic, strong) CBCharacteristic *bodyAnalysisResultCharacteristic;
@end

NSString * const BodyAnalysisServiceUUID = @"61E3C3AD-4782-44FB-8E3D-C5CE25FE88B1";
NSString * const BodyAnalysisResultCharacteristicUUID = @"97909CF7-FD2B-4F2C-ABFE-6A55AB72CFCF";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Scan for all available CoreBluetooth LE devices
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{ CBCentralManagerOptionShowPowerAlertKey : @NO }];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // Determine the state of the peripheral
    if (central.state == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        // The peripheral only advertises the user info service
        NSArray *services = @[[CBUUID UUIDWithString:BodyAnalysisServiceUUID]];
        [self.centralManager scanForPeripheralsWithServices:services options:nil];
    }
    else if (central.state == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
        NSAssert(NO, @"When does this happen?");
    }
    else if (central.state == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
        NSAssert(NO, @"When does this happen?");
    }
    else if (central.state == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *localName = advertisementData[CBAdvertisementDataLocalNameKey];
    if (localName.length > 0) {
        NSLog(@"Found peripheral: %@", localName);

        self.selectedPeripheral = peripheral;
        peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    NSString *connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    NSLog(@"%@", connected);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@ for %@", service.UUID, peripheral.name);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

    if ([service.UUID isEqual:[CBUUID UUIDWithString:BodyAnalysisServiceUUID]]) {
        for (CBCharacteristic *someCharacteristic in service.characteristics) {
            if ([someCharacteristic.UUID isEqual:[CBUUID UUIDWithString:BodyAnalysisResultCharacteristicUUID]] && !self.bodyAnalysisResultCharacteristic) {
                NSLog(@"Found BodyAnalysisResultCharacteristicUUID char, will enable notifications");
                [self.selectedPeripheral setNotifyValue:YES forCharacteristic:someCharacteristic];
                self.bodyAnalysisResultCharacteristic = someCharacteristic;
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic error");
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BodyAnalysisResultCharacteristicUUID]]) {

        NSData *data = characteristic.value;
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSLog(@"data.length = %u", data.length);
        NSLog(@"Measurement data string: %@", dataString);

    }
}

@end